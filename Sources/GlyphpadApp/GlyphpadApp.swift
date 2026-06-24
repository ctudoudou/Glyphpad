import AppKit
import Carbon
import Darwin
import GlyphpadCore
import GlyphpadStorage
import SwiftUI
import UniformTypeIdentifiers

private extension Notification.Name {
    static let glyphpadToggleSettings = Notification.Name("GlyphpadToggleSettings")
}

private enum PerformanceLog {
    static func start() -> TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    static func finish(_ name: String, startedAt start: TimeInterval, metadata: String = "") {
        let elapsedMilliseconds = (ProcessInfo.processInfo.systemUptime - start) * 1_000
        let suffix = metadata.isEmpty ? "" : " \(metadata)"
        NSLog("Glyphpad performance: \(name) %.1fms\(suffix)", elapsedMilliseconds)
    }

    @discardableResult
    static func measure<T>(_ name: String, metadata: String = "", _ work: () throws -> T) rethrows -> T {
        let startedAt = start()
        defer {
            finish(name, startedAt: startedAt, metadata: metadata)
        }
        return try work()
    }
}

@main
@MainActor
private struct GlyphpadMain {
    private static var delegate: LauncherAppDelegate?

    static func main() {
        let app = NSApplication.shared
        let delegate = LauncherAppDelegate()
        Self.delegate = delegate
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}

@MainActor
private final class LauncherAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: LauncherWindow?
    private var settingsWindow: NSWindow?
    private let settingsController = LauncherSettingsController()
    private var hotKeyManager: GlobalHotKeyManager?
    private var isDismissingLauncher = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMenu()
        installGlobalHotKey()
        NSApplication.shared.presentationOptions = [.autoHideDock, .autoHideMenuBar]
        NotificationCenter.default.addObserver(
            forName: .glyphpadToggleSettings,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.showSettingsWindow()
            }
        }
        showLauncher()
    }

    func applicationWillTerminate(_ notification: Notification) {
        settingsController.flush()
    }

    private func toggleLauncher() {
        if window != nil {
            dismissLauncher()
        } else {
            showLauncher()
        }
    }

    private func showLauncher() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let startedAt = PerformanceLog.start()
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let windowFrame = screenFrame.insetBy(dx: -2, dy: -2)
        let window = LauncherWindow(contentRect: windowFrame)
        window.dismissHandler = { [weak self] in self?.dismissLauncher() }

        let rootView = LauncherView(settingsController: settingsController) { [weak self] in
            self?.dismissLauncher()
        }

        let hostingView = EdgePinnedHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: windowFrame.size)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.black.cgColor
        window.contentView = hostingView
        window.setFrame(windowFrame, display: true)
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        self.window = window
        isDismissingLauncher = false

        NSApplication.shared.unhide(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
        } completionHandler: {
            PerformanceLog.finish("launcher.open", startedAt: startedAt)
            Task { @MainActor in
                NSApplication.shared.setActivationPolicy(.accessory)
            }
        }
    }

    private func dismissLauncher() {
        let startedAt = PerformanceLog.start()
        guard let window else {
            PerformanceLog.finish("launcher.close.no-window", startedAt: startedAt)
            return
        }
        guard !isDismissingLauncher else {
            PerformanceLog.finish("launcher.close.already-dismissing", startedAt: startedAt)
            return
        }

        isDismissingLauncher = true
        window.ignoresMouseEvents = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0
        } completionHandler: {
            DispatchQueue.main.async {
                PerformanceLog.finish("launcher.close", startedAt: startedAt)
                window.orderOut(nil)
                window.close()
                self.window = nil
                self.isDismissingLauncher = false
                if self.settingsWindow?.isVisible == true {
                    return
                }
                self.settingsController.flush()
                NSApplication.shared.hide(nil)
            }
        }
    }

    @objc private func openSettingsFromMenu(_ sender: Any?) {
        showSettingsWindow()
    }

    private func showSettingsWindow() {
        removeLauncherWindowForSettings()

        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "Glyphpad Settings"
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.delegate = self
        settingsWindow.level = .floating
        settingsWindow.minSize = NSSize(width: 700, height: 520)
        settingsWindow.center()
        settingsWindow.contentView = NSHostingView(rootView: SettingsWindowView(controller: settingsController))
        settingsWindow.makeKeyAndOrderFront(nil)
        self.settingsWindow = settingsWindow
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func removeLauncherWindowForSettings() {
        guard let window else {
            return
        }

        window.ignoresMouseEvents = true
        window.alphaValue = 0
        window.orderOut(nil)
        window.close()
        self.window = nil
        isDismissingLauncher = false
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow, closingWindow === settingsWindow else {
            return
        }

        settingsWindow = nil
        if window == nil {
            settingsController.flush()
        }
    }

    private func installGlobalHotKey() {
        hotKeyManager = GlobalHotKeyManager {
            Task { @MainActor [weak self] in
                self?.toggleLauncher()
            }
        }
        hotKeyManager?.registerDefaultHotKey()
    }

    private func installMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(
            NSMenuItem(
                title: "Settings...",
                action: #selector(openSettingsFromMenu(_:)),
                keyEquivalent: ","
            )
        )
        appMenu.items.last?.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "Quit Glyphpad",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )
        appMenuItem.submenu = appMenu

        mainMenu.addItem(appMenuItem)
        NSApplication.shared.mainMenu = mainMenu
    }
}

private final class GlobalHotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let action: @Sendable () -> Void

    init(action: @escaping @Sendable () -> Void) {
        self.action = action
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    func registerDefaultHotKey() {
        let eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, userData in
                guard let userData else {
                    return noErr
                }

                var hotKeyID = EventHotKeyID()
                let result = GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard result == noErr, hotKeyID.id == 1 else {
                    return noErr
                }

                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.action()
                return noErr
            },
            1,
            [eventType],
            userData,
            &eventHandlerRef
        )
        guard installStatus == noErr else {
            NSLog("Failed to install Glyphpad hot key handler: \(installStatus)")
            return
        }

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: 1)
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if registerStatus != noErr {
            NSLog("Failed to register Glyphpad global hot key: \(registerStatus)")
        }
    }

    private static let signature: OSType = {
        var result: OSType = 0
        for scalar in "GLYP".unicodeScalars {
            result = (result << 8) + OSType(scalar.value)
        }
        return result
    }()
}

private final class LauncherWindow: NSWindow {
    var dismissHandler: (() -> Void)?

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        title = "Glyphpad"
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .stationary]
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            dismissHandler?()
            return
        }

        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command),
           event.charactersIgnoringModifiers == "," {
            NotificationCenter.default.post(name: .glyphpadToggleSettings, object: nil)
            return
        }

        super.keyDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command),
           event.charactersIgnoringModifiers == "," {
            NotificationCenter.default.post(name: .glyphpadToggleSettings, object: nil)
            return true
        }

        return super.performKeyEquivalent(with: event)
    }
}

private final class EdgePinnedHostingView<Content: View>: NSHostingView<Content> {
    override var safeAreaInsets: NSEdgeInsets {
        NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    override var additionalSafeAreaInsets: NSEdgeInsets {
        get { NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) }
        set {}
    }
}

private struct LauncherView: View {
    @ObservedObject var settingsController: LauncherSettingsController
    let onDismiss: () -> Void

    @StateObject private var library = ApplicationLibrary()
    @State private var searchText = ""
    @State private var openFolder: FolderRecord?

    private var filteredItems: [LauncherItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return library.launcherItems
        }

        return library.launcherItems.filter { item in
            switch item {
            case .app(let app):
                app.displayName.localizedCaseInsensitiveContains(query)
                    || app.bundleIdentifier?.localizedCaseInsensitiveContains(query) == true
            case .folder(let folder):
                folder.name.localizedCaseInsensitiveContains(query)
            }
        }
    }

    private func gridColumns(for settings: LauncherSettings) -> [GridItem] {
        Array(
            repeating: GridItem(.fixed(settings.tileWidth), spacing: settings.horizontalSpacing, alignment: .top),
            count: settings.clampedColumns
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                DesktopBackdrop(settings: settingsController.settings)
                    .onTapGesture {
                        dismiss()
                    }

                VStack(spacing: 34) {
                    SearchField(text: $searchText)
                        .padding(.top, max(42, proxy.safeAreaInsets.top + 28))

                    launcherContent(maxSize: proxy.size)

                    pageIndicator(settings: settingsController.settings.fitting(maxSize: proxy.size))
                        .padding(.bottom, max(28, proxy.safeAreaInsets.bottom + 18))
                }
                .frame(width: proxy.size.width, height: proxy.size.height)

                if let folder = openFolder {
                    FolderOverlay(
                        folder: folder,
                        apps: library.apps(in: folder),
                        settings: settingsController.settings.fitting(maxSize: proxy.size),
                        rename: { name in
                            library.rename(folder: folder, name: name)
                            openFolder = library.folder(id: folder.id)
                        },
                        launch: { app in
                            library.launch(app)
                            dismiss()
                        },
                        close: {
                            openFolder = nil
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .animation(.easeOut(duration: 0.18), value: openFolder?.id)
        }
        .ignoresSafeArea()
        .focusable()
        .onAppear {
            library.reload()
        }
        .onExitCommand {
            dismiss()
        }
    }

    @ViewBuilder
    private func launcherContent(maxSize: CGSize) -> some View {
        let settings = settingsController.settings.fitting(maxSize: maxSize)
        let maxGridWidth = min(
            maxSize.width - 96,
            CGFloat(settings.clampedColumns) * settings.tileWidth
                + CGFloat(settings.clampedColumns - 1) * settings.horizontalSpacing
        )
        let maxGridHeight = max(
            260,
            min(
                maxSize.height - 170,
                CGFloat(settings.clampedRows) * settings.tileHeight
                    + CGFloat(settings.clampedRows - 1) * settings.verticalSpacing
            )
        )

        if filteredItems.isEmpty {
            EmptySearchView()
                .frame(width: maxGridWidth, height: maxGridHeight)
        } else {
            switch settings.navigationMode {
            case .verticalScroll:
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .top) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dismiss()
                            }

                        LazyVGrid(columns: gridColumns(for: settings), spacing: settings.verticalSpacing) {
                            ForEach(filteredItems) { item in
                                LauncherItemTile(
                                    item: item,
                                    settings: settings,
                                    library: library,
                                    openFolder: { folder in self.openFolder = folder },
                                    launch: { app in
                                        library.launch(app)
                                        dismiss()
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .frame(width: maxGridWidth, height: maxGridHeight)
                .clipped()
            case .horizontalPages:
                PagedLauncherGrid(
                    items: filteredItems,
                    settings: settings,
                    maxGridWidth: maxGridWidth,
                    maxGridHeight: maxGridHeight,
                    library: library,
                    openFolder: { folder in self.openFolder = folder },
                    dismiss: dismiss,
                    launch: { app in
                        library.launch(app)
                        dismiss()
                    }
                )
            }
        }
    }

    private func dismiss() {
        onDismiss()
    }

    @ViewBuilder
    private func pageIndicator(settings: LauncherSettings) -> some View {
        if settings.navigationMode == .horizontalPages {
            let pageSize = max(1, settings.clampedColumns * settings.clampedRows)
            let pageCount = max(1, Int(ceil(Double(filteredItems.count) / Double(pageSize))))
            PageDots(pageCount: pageCount)
        } else {
            Color.clear.frame(width: 1, height: 8)
        }
    }
}

@MainActor
private final class LauncherSettingsController: ObservableObject {
    @Published private(set) var settings: LauncherSettings

    private var repository: SQLiteLauncherSettingsRepository?
    private var persistTask: Task<Void, Never>?

    init() {
        do {
            let store = try AppStoreFactory.makeStore()
            let repository = store.launcherSettingsRepository()
            self.repository = repository
            self.settings = try repository.load()
        } catch {
            NSLog("Failed to load launcher settings: \(error.localizedDescription)")
            self.repository = nil
            self.settings = .default
        }
    }

    func update(_ transform: (inout LauncherSettings) -> Void) {
        var next = settings
        transform(&next)
        settings = next.clamped()
        schedulePersist()
    }

    deinit {
        persistTask?.cancel()
    }

    func flush() {
        persistTask?.cancel()
        persist()
    }

    private func schedulePersist() {
        persistTask?.cancel()
        let nextSettings = settings
        let repository = repository
        persistTask = Task {
            try? await Task.sleep(for: .milliseconds(180))
            do {
                try repository?.save(nextSettings)
            } catch {
                NSLog("Failed to save launcher settings: \(error.localizedDescription)")
            }
        }
    }

    private func persist() {
        do {
            try repository?.save(settings)
        } catch {
            NSLog("Failed to save launcher settings: \(error.localizedDescription)")
        }
    }
}

private enum AppStoreFactory {
    static func makeStore() throws -> GlyphpadStore {
        let fileManager = FileManager.default
        let directory = try applicationSupportDirectory(fileManager: fileManager)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent("Glyphpad.sqlite").path
        return try GlyphpadStore(path: path)
    }

    private static func applicationSupportDirectory(fileManager: FileManager) throws -> URL {
        if let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            return directory.appendingPathComponent("Glyphpad", isDirectory: true)
        }

        return URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/Glyphpad", isDirectory: true)
    }
}

private struct SettingsWindowView: View {
    @ObservedObject var controller: LauncherSettingsController
    @State private var selectedSection: SettingsSection = .layout

    var body: some View {
        HStack(spacing: 0) {
            settingsSidebar

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    sectionHeader
                    selectedSectionContent
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 26)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.74))
        }
        .toggleStyle(.switch)
        .controlSize(.regular)
        .frame(width: 760, height: 560)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Glyphpad")
                    .font(.system(size: 22, weight: .semibold))
                Text("Launchpad controls")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)

            VStack(spacing: 5) {
                ForEach(SettingsSection.allCases) { section in
                    SettingsSidebarButton(
                        section: section,
                        isSelected: selectedSection == section
                    ) {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            selectedSection = section
                        }
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text("Local state")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Label("SQLite backed", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .frame(width: 190)
    }

    private var sectionHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: selectedSection.symbolName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 42, height: 42)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(selectedSection.title)
                    .font(.system(size: 25, weight: .semibold))
                Text(selectedSection.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var selectedSectionContent: some View {
        switch selectedSection {
        case .layout:
            layoutSettings
        case .appearance:
            appearanceSettings
        case .automation:
            automationSettings
        }
    }

    private var layoutSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsGroup(title: "Grid", subtitle: "Tune density while keeping icons inside the screen bounds.") {
                SettingToggleRow(
                    title: "Auto arrange",
                    detail: "Fit rows and columns to the current display automatically.",
                    isOn: Binding(
                        get: { controller.settings.autoArrange },
                        set: { value in controller.update { $0.autoArrange = value } }
                    )
                )

                Divider()

                SettingStepperRow(
                    title: "Columns",
                    detail: "Icons shown per row.",
                    value: controller.settings.clampedColumns,
                    range: 4...12,
                    isDisabled: controller.settings.autoArrange,
                    binding: Binding(
                        get: { controller.settings.columns },
                        set: { value in controller.update { $0.columns = value } }
                    )
                )

                SettingStepperRow(
                    title: "Rows",
                    detail: "Rows shown per page.",
                    value: controller.settings.clampedRows,
                    range: 3...8,
                    isDisabled: controller.settings.autoArrange,
                    binding: Binding(
                        get: { controller.settings.rows },
                        set: { value in controller.update { $0.rows = value } }
                    )
                )

                Divider()

                SettingSliderRow(
                    title: "Icon size",
                    detail: "Controls the visual weight of apps and folders.",
                    valueText: "\(Int(controller.settings.clampedIconSize)) pt",
                    value: Binding(
                        get: { Double(controller.settings.iconSize) },
                        set: { value in controller.update { $0.iconSize = CGFloat(value) } }
                    ),
                    range: 48...112,
                    step: 2
                )
            }

            SettingsGroup(title: "Navigation", subtitle: "Vertical mode scrolls. Horizontal mode snaps page by page.") {
                Picker("Navigation", selection: Binding(
                    get: { controller.settings.navigationMode },
                    set: { value in controller.update { $0.navigationMode = value } }
                )) {
                    Text("Vertical Scroll").tag(LauncherNavigationMode.verticalScroll)
                    Text("Horizontal Pages").tag(LauncherNavigationMode.horizontalPages)
                }
                .pickerStyle(.segmented)

                LayoutPreview(settings: controller.settings)
            }

            SettingsGroup(title: "Keyboard", subtitle: "Keep Glyphpad ready without showing a Dock icon.") {
                HStack(spacing: 16) {
                    SettingFieldLabel(
                        title: "Show or hide launcher",
                        detail: "Glyphpad stays in the background after closing the launcher."
                    )
                    Spacer()
                    HStack(spacing: 5) {
                        KeyCap("Option")
                        KeyCap("Space")
                    }
                }
            }
        }
    }

    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsGroup(title: "Background", subtitle: "Choose the launcher backdrop and blur strength.") {
                BackgroundPreview(settings: controller.settings)

                HStack(spacing: 10) {
                    Button {
                        chooseBackgroundImage()
                    } label: {
                        Label("Choose Image", systemImage: "photo")
                    }

                    Button {
                        controller.update { $0.backgroundImagePath = nil }
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .disabled(controller.settings.backgroundImagePath == nil)
                }

                if let backgroundImagePath = controller.settings.backgroundImagePath {
                    Text(backgroundImagePath)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }

                SettingSliderRow(
                    title: "Blur",
                    detail: "Softens the selected image behind app icons.",
                    valueText: "\(Int(controller.settings.clampedBackgroundBlurRadius))",
                    value: Binding(
                        get: { Double(controller.settings.backgroundBlurRadius) },
                        set: { value in controller.update { $0.backgroundBlurRadius = CGFloat(value) } }
                    ),
                    range: 0...48,
                    step: 1
                )
            }
        }
    }

    private var automationSettings: some View {
        SettingsGroup(title: "Classifier API", subtitle: "Used later by automatic app classification.") {
            VStack(alignment: .leading, spacing: 8) {
                SettingFieldLabel(title: "Endpoint", detail: "OpenAI-compatible endpoint for classification.")
                TextField("https://api.example.com/v1", text: Binding(
                    get: { controller.settings.apiEndpoint ?? "" },
                    set: { value in controller.update { $0.apiEndpoint = value } }
                ))
                .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                SettingFieldLabel(title: "API Key", detail: "Stored locally in the Glyphpad SQLite settings record.")
                SecureField("API key", text: Binding(
                    get: { controller.settings.apiKey ?? "" },
                    set: { value in controller.update { $0.apiKey = value } }
                ))
                .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 8) {
                Image(systemName: apiStatusSymbol)
                    .foregroundStyle(apiStatusColor)
                Text(apiStatusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }

    private func chooseBackgroundImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        NSApplication.shared.activate(ignoringOtherApps: true)

        let responseHandler: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK, let url = panel.url else {
                return
            }
            controller.update { $0.backgroundImagePath = url.path }
        }

        if let settingsWindow = NSApplication.shared.windows.first(where: { window in
            window.title == "Glyphpad Settings" && window.isVisible
        }) {
            settingsWindow.makeKeyAndOrderFront(nil)
            panel.beginSheetModal(for: settingsWindow, completionHandler: responseHandler)
        } else {
            panel.begin(completionHandler: responseHandler)
        }
    }

    private var apiStatusText: String {
        if controller.settings.apiEndpoint != nil, controller.settings.apiKey != nil {
            return "Endpoint and key configured"
        }
        if controller.settings.apiEndpoint != nil {
            return "Endpoint configured, API key missing"
        }
        return "API is not configured"
    }

    private var apiStatusSymbol: String {
        controller.settings.apiEndpoint != nil && controller.settings.apiKey != nil
            ? "checkmark.circle.fill"
            : "exclamationmark.circle"
    }

    private var apiStatusColor: Color {
        controller.settings.apiEndpoint != nil && controller.settings.apiKey != nil
            ? .green
            : .secondary
    }
}

private enum SettingsSection: CaseIterable, Identifiable {
    case layout
    case appearance
    case automation

    var id: Self { self }

    var title: String {
        switch self {
        case .layout:
            return "Layout"
        case .appearance:
            return "Appearance"
        case .automation:
            return "API"
        }
    }

    var subtitle: String {
        switch self {
        case .layout:
            return "Rows, columns, icon size, and paging"
        case .appearance:
            return "Background image and blur"
        case .automation:
            return "Provider settings for classification"
        }
    }

    var symbolName: String {
        switch self {
        case .layout:
            return "square.grid.3x3.fill"
        case .appearance:
            return "photo.fill"
        case .automation:
            return "sparkles"
        }
    }
}

private struct SettingsSidebarButton: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(section.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                content()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct SettingFieldLabel: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}

private struct KeyCap: View {
    let label: String

    init(_ label: String) {
        self.label = label
    }

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 9)
            .frame(height: 26)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            }
    }
}

private struct SettingToggleRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            SettingFieldLabel(title: title, detail: detail)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

private struct SettingStepperRow: View {
    let title: String
    let detail: String
    let value: Int
    let range: ClosedRange<Int>
    let isDisabled: Bool
    @Binding var binding: Int

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            SettingFieldLabel(title: title, detail: detail)
            Spacer()
            Text("\(value)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(isDisabled ? .secondary : .primary)
                .frame(width: 34, alignment: .trailing)
            Stepper("", value: $binding, in: range)
                .labelsHidden()
                .disabled(isDisabled)
        }
        .opacity(isDisabled ? 0.52 : 1)
    }
}

private struct SettingSliderRow: View {
    let title: String
    let detail: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SettingFieldLabel(title: title, detail: detail)
                Spacer()
                Text(valueText)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

private struct LayoutPreview: View {
    let settings: LauncherSettings

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.18))
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(14), spacing: 8), count: min(settings.clampedColumns, 8)),
                    spacing: 8
                ) {
                    ForEach(0..<min(settings.clampedRows * min(settings.clampedColumns, 8), 32), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(index % 5 == 0 ? Color.accentColor.opacity(0.84) : Color.primary.opacity(0.22))
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .frame(width: 156, height: 88)

            VStack(alignment: .leading, spacing: 5) {
                Text("\(settings.clampedColumns) x \(settings.clampedRows)")
                    .font(.system(size: 18, weight: .semibold))
                Text(settings.navigationMode == .horizontalPages ? "Snapped pages" : "Continuous vertical scroll")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Icon \(Int(settings.clampedIconSize)) pt")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

private struct BackgroundPreview: View {
    let settings: LauncherSettings

    var body: some View {
        ZStack {
            if let image = backgroundImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: min(settings.clampedBackgroundBlurRadius / 4, 10))
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.10, blue: 0.11),
                        Color(red: 0.23, green: 0.23, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            Color.black.opacity(0.18)

            HStack(spacing: 18) {
                ForEach(0..<5, id: \.self) { index in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(index == 2 ? Color.accentColor : Color.white.opacity(0.78))
                            .frame(width: 34, height: 34)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.white.opacity(0.62))
                            .frame(width: 34, height: 4)
                    }
                }
            }
        }
        .frame(height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
    }

    private var backgroundImage: NSImage? {
        guard let path = settings.backgroundImagePath else {
            return nil
        }
        return NSImage(contentsOfFile: path)
    }
}

private struct FolderOverlay: View {
    let folder: FolderRecord
    let apps: [InstalledApplication]
    let settings: LauncherSettings
    let rename: (String) -> Void
    let launch: (InstalledApplication) -> Void
    let close: () -> Void

    @State private var draftName: String

    init(
        folder: FolderRecord,
        apps: [InstalledApplication],
        settings: LauncherSettings,
        rename: @escaping (String) -> Void,
        launch: @escaping (InstalledApplication) -> Void,
        close: @escaping () -> Void
    ) {
        self.folder = folder
        self.apps = apps
        self.settings = settings
        self.rename = rename
        self.launch = launch
        self.close = close
        _draftName = State(initialValue: folder.name)
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(settings.tileWidth), spacing: settings.horizontalSpacing, alignment: .top),
            count: min(max(apps.count, 2), 4)
        )
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.24)
                .ignoresSafeArea()
                .onTapGesture(perform: close)

            VStack(spacing: 20) {
                TextField("Folder name", text: $draftName, onCommit: {
                    rename(draftName)
                })
                .textFieldStyle(.plain)
                .font(.system(size: 24, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .frame(width: 320)
                .padding(.top, 24)

                LazyVGrid(columns: columns, spacing: settings.verticalSpacing) {
                    ForEach(apps) { app in
                        AppTile(app: app, settings: settings) {
                            launch(app)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.36), radius: 28, x: 0, y: 16)
        }
    }
}

private struct SettingValueLabel: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.white.opacity(0.68))
        }
    }
}

private struct PagedLauncherGrid: View {
    let items: [LauncherItem]
    let settings: LauncherSettings
    let maxGridWidth: CGFloat
    let maxGridHeight: CGFloat
    @ObservedObject var library: ApplicationLibrary
    let openFolder: (FolderRecord) -> Void
    let dismiss: () -> Void
    let launch: (InstalledApplication) -> Void
    @State private var currentPageID: Int?

    private var pageSize: Int {
        settings.clampedColumns * settings.clampedRows
    }

    private var pages: [[LauncherItem]] {
        stride(from: 0, to: items.count, by: pageSize).map { index in
            Array(items[index..<min(index + pageSize, items.count)])
        }
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.fixed(settings.tileWidth), spacing: settings.horizontalSpacing, alignment: .top),
            count: settings.clampedColumns
        )
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismiss()
                    }

                LazyHStack(spacing: 0) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { pageIndex, page in
                        LazyVGrid(columns: columns, spacing: settings.verticalSpacing) {
                            ForEach(page) { item in
                                LauncherItemTile(
                                    item: item,
                                    settings: settings,
                                    library: library,
                                    openFolder: openFolder,
                                    launch: launch
                                )
                            }
                        }
                        .frame(width: maxGridWidth, height: maxGridHeight, alignment: .top)
                        .id(pageIndex)
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(1 - min(abs(phase.value) * 0.045, 0.045))
                                .opacity(1 - min(abs(phase.value) * 0.16, 0.16))
                                .offset(x: phase.value * -18)
                        }
                    }
                }
                .scrollTargetLayout()
            }
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentPageID)
        .animation(.smooth(duration: 0.38, extraBounce: 0.16), value: currentPageID)
        .frame(width: maxGridWidth, height: maxGridHeight)
        .clipped()
    }
}

private struct LauncherItemTile: View {
    let item: LauncherItem
    let settings: LauncherSettings
    @ObservedObject var library: ApplicationLibrary
    let openFolder: (FolderRecord) -> Void
    let launch: (InstalledApplication) -> Void

    var body: some View {
        tile
            .onDrag {
                NSItemProvider(object: item.id as NSString)
            }
            .onDrop(
                of: [UTType.text],
                delegate: LauncherItemDropDelegate(
                    targetItemID: item.id,
                    targetIsApp: item.isApp,
                    library: library
                )
            )
    }

    @ViewBuilder
    private var tile: some View {
        switch item {
        case .app(let app):
            AppTile(app: app, settings: settings) {
                launch(app)
            }
        case .folder(let folder):
            FolderTile(
                folder: folder,
                memberApps: library.apps(in: folder),
                settings: settings
            ) {
                openFolder(folder)
            }
        }
    }

}

private struct LauncherItemDropDelegate: DropDelegate {
    let targetItemID: String
    let targetIsApp: Bool
    @ObservedObject var library: ApplicationLibrary

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.text])
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [UTType.text]).first else {
            return false
        }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let draggedItemID = object as? String else {
                return
            }

            Task { @MainActor in
                _ = library.handleDrop(
                    draggedItemID: draggedItemID,
                    targetItemID: targetItemID,
                    shouldCreateFolder: targetIsApp
                )
            }
        }
        return true
    }
}

private struct SearchField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))

            TextField("Search", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .focused($isFocused)
        }
        .padding(.horizontal, 20)
        .frame(width: 420, height: 46)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.20), lineWidth: 1)
        }
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
        }
    }
}

private struct AppTile: View {
    let app: InstalledApplication
    let settings: LauncherSettings
    let launch: () -> Void

    var body: some View {
        Button(action: launch) {
            VStack(spacing: 9) {
                Image(nsImage: app.icon)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: settings.clampedIconSize, height: settings.clampedIconSize)
                    .shadow(color: .black.opacity(0.26), radius: 10, x: 0, y: 6)

                Text(app.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
                    .frame(width: settings.tileWidth, height: 34, alignment: .top)
            }
            .frame(width: settings.tileWidth, height: settings.tileHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(app.bundleIdentifier ?? app.url.path)
    }
}

private struct FolderTile: View {
    let folder: FolderRecord
    let memberApps: [InstalledApplication]
    let settings: LauncherSettings
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            VStack(spacing: 9) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.white.opacity(0.14))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.fixed(settings.clampedIconSize * 0.28), spacing: 4), count: 2),
                        spacing: 4
                    ) {
                        ForEach(memberApps.prefix(4)) { app in
                            Image(nsImage: app.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: settings.clampedIconSize * 0.28, height: settings.clampedIconSize * 0.28)
                        }
                    }
                }
                .frame(width: settings.clampedIconSize, height: settings.clampedIconSize)
                .shadow(color: .black.opacity(0.26), radius: 10, x: 0, y: 6)

                Text(folder.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
                    .frame(width: settings.tileWidth, height: 34, alignment: .top)
            }
            .frame(width: settings.tileWidth, height: settings.tileHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(folder.name)
    }
}

private struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "app.dashed")
                .font(.system(size: 42, weight: .medium))
            Text("No apps found")
                .font(.system(size: 18, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.76))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PageDots: View {
    let pageCount: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(index == 0 ? .white.opacity(0.9) : .white.opacity(0.32))
                    .frame(width: 7, height: 7)
            }
        }
        .frame(height: 8)
    }
}

private struct DesktopBackdrop: View {
    let settings: LauncherSettings

    var body: some View {
        ZStack {
            if let image = backgroundImage {
                GeometryReader { proxy in
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .blur(radius: settings.clampedBackgroundBlurRadius)
                        .scaleEffect(settings.clampedBackgroundBlurRadius > 0 ? 1.06 : 1)
                        .clipped()
                }
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.09),
                        Color(red: 0.15, green: 0.15, blue: 0.16)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            Color.black.opacity(backgroundImage == nil ? 0.34 : 0.26)

            RadialGradient(
                colors: [
                    Color.white.opacity(0.13),
                    Color.white.opacity(0.02),
                    Color.black.opacity(0.18)
                ],
                center: .top,
                startRadius: 80,
                endRadius: 760
            )
        }
    }

    private var backgroundImage: NSImage? {
        guard let path = settings.backgroundImagePath else {
            return nil
        }

        return NSImage(contentsOfFile: path)
    }
}

private struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
    }
}

@MainActor
private final class ApplicationLibrary: ObservableObject, @unchecked Sendable {
    @Published private(set) var apps: [InstalledApplication] = []
    @Published private(set) var folders: [FolderRecord] = []
    @Published private(set) var launcherItems: [LauncherItem] = []

    private let iconCache = IconCache()
    private let appRepository: SQLiteAppRepository?
    private let folderRepository: SQLiteFolderRepository?
    private let layoutRepository: SQLiteLayoutRepository?
    private var refreshTask: Task<Void, Never>?
    private var directoryWatcher: ApplicationDirectoryWatcher?
    private var appIndex: [String: InstalledApplication] = [:]
    private var layoutOrder: [String] = []

    init() {
        do {
            let store = try AppStoreFactory.makeStore()
            self.appRepository = store.appRepository()
            self.folderRepository = store.folderRepository()
            self.layoutRepository = store.layoutRepository()
        } catch {
            NSLog("Failed to open app cache store: \(error.localizedDescription)")
            self.appRepository = nil
            self.folderRepository = nil
            self.layoutRepository = nil
        }
    }

    func reload(reason: String = "manual") {
        startWatchingApplicationDirectories()
        let reloadStartedAt = PerformanceLog.start()

        loadLayout()
        loadFolders()
        PerformanceLog.measure("library.cache.load", metadata: "reason=\(reason)") {
            loadCachedApps()
        }

        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            let scanStartedAt = PerformanceLog.start()
            let scannedApps = await Task.detached(priority: .userInitiated) {
                ApplicationScanner().scan()
            }.value
            PerformanceLog.finish("library.scan", startedAt: scanStartedAt, metadata: "count=\(scannedApps.count) reason=\(reason)")

            guard !Task.isCancelled else {
                return
            }

            guard let self else {
                return
            }

            PerformanceLog.measure("library.publish", metadata: "count=\(scannedApps.count) reason=\(reason)") {
                self.publish(scannedApps)
            }
            PerformanceLog.measure("library.persist", metadata: "count=\(scannedApps.count) reason=\(reason)") {
                self.persist(scannedApps)
            }
            PerformanceLog.finish("library.reload", startedAt: reloadStartedAt, metadata: "reason=\(reason)")
        }
    }

    func launch(_ app: InstalledApplication) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        NSWorkspace.shared.openApplication(at: app.url, configuration: configuration) { _, error in
            if let error {
                NSLog("Failed to launch \(app.url.path): \(error.localizedDescription)")
            }
        }
    }

    func folder(id: UUID) -> FolderRecord? {
        folders.first { $0.id == id }
    }

    func apps(in folder: FolderRecord) -> [InstalledApplication] {
        folder.appBundleIdentifiers.compactMap { appIndex[$0] }
    }

    func handleDrop(draggedItemID: String, targetItemID: String, shouldCreateFolder: Bool) -> Bool {
        guard draggedItemID != targetItemID else {
            return false
        }

        if let targetFolderID = Self.folderID(from: targetItemID),
           let draggedAppID = Self.appID(from: draggedItemID) {
            return add(appID: draggedAppID, toFolderID: targetFolderID)
        }

        if shouldCreateFolder,
           let sourceAppID = Self.appID(from: draggedItemID),
           let targetAppID = Self.appID(from: targetItemID) {
            return createFolder(sourceAppID: sourceAppID, targetAppID: targetAppID) != nil
        }

        return moveItem(draggedItemID: draggedItemID, before: targetItemID)
    }

    func createFolder(sourceAppID: String, targetAppID: String) -> FolderRecord? {
        guard sourceAppID != targetAppID else {
            return nil
        }
        guard folderRepository != nil else {
            return nil
        }
        guard appIndex[sourceAppID] != nil, appIndex[targetAppID] != nil else {
            return nil
        }
        if folders.contains(where: { folder in
            folder.appBundleIdentifiers.contains(sourceAppID) || folder.appBundleIdentifiers.contains(targetAppID)
        }) {
            return nil
        }

        do {
            let insertIndex = launcherItems.firstIndex { $0.id == Self.layoutID(kind: .app, targetIdentifier: targetAppID) } ?? launcherItems.count
            let folder = try folderRepository?.create(
                name: "Untitled Folder",
                appBundleIdentifiers: [targetAppID, sourceAppID],
                positionIndex: folders.count
            )
            loadFolders()
            rebuildLauncherItems()
            if let folder {
                _ = moveItem(draggedItemID: Self.layoutID(kind: .folder, targetIdentifier: folder.id.uuidString), to: insertIndex)
            }
            return folder
        } catch {
            NSLog("Failed to create folder: \(error.localizedDescription)")
            return nil
        }
    }

    func rename(folder: FolderRecord, name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        do {
            try folderRepository?.rename(folderID: folder.id, name: trimmedName)
            loadFolders()
        } catch {
            NSLog("Failed to rename folder: \(error.localizedDescription)")
        }
    }

    private func add(appID: String, toFolderID folderID: UUID) -> Bool {
        guard appIndex[appID] != nil else {
            return false
        }
        guard let folder = folder(id: folderID), !folder.appBundleIdentifiers.contains(appID) else {
            return false
        }

        do {
            try folderRepository?.updateMembers(
                folderID: folderID,
                appBundleIdentifiers: folder.appBundleIdentifiers + [appID]
            )
            loadFolders()
            rebuildLauncherItems()
            saveCurrentLayout()
            return true
        } catch {
            NSLog("Failed to add app to folder: \(error.localizedDescription)")
            return false
        }
    }

    private func loadCachedApps() {
        guard let appRepository else {
            return
        }

        do {
            let cachedApps = try appRepository.fetchAll().compactMap { record in
                InstalledApplication(record: record, iconCache: iconCache)
            }
            if !cachedApps.isEmpty {
                setApps(cachedApps)
            }
        } catch {
            NSLog("Failed to load cached apps: \(error.localizedDescription)")
        }
    }

    private func loadFolders() {
        do {
            folders = try folderRepository?.fetchAll() ?? []
            rebuildLauncherItems()
        } catch {
            NSLog("Failed to load folders: \(error.localizedDescription)")
        }
    }

    private func loadLayout() {
        do {
            layoutOrder = try layoutRepository?.fetchAll().map(Self.layoutID(for:)) ?? []
        } catch {
            NSLog("Failed to load launcher layout: \(error.localizedDescription)")
            layoutOrder = []
        }
    }

    private func publish(_ scannedApps: [ScannedApplication]) {
        let nextApps = scannedApps.map { app in
            InstalledApplication(scannedApp: app, iconCache: iconCache)
        }

        guard appSignature(nextApps) != appSignature(apps) else {
            return
        }

        setApps(nextApps)
    }

    private func persist(_ scannedApps: [ScannedApplication]) {
        guard let appRepository else {
            return
        }

        do {
            let existingRecords = Dictionary(
                uniqueKeysWithValues: try appRepository.fetchAll().map { ($0.bundleIdentifier, $0) }
            )
            var changedCount = 0
            for app in scannedApps {
                let nextRecord = app.appRecord()
                if let existingRecord = existingRecords[nextRecord.bundleIdentifier],
                   existingRecord.displayName == nextRecord.displayName,
                   existingRecord.executablePath == nextRecord.executablePath {
                    continue
                }

                try appRepository.upsert(nextRecord)
                changedCount += 1
            }
            NSLog("Glyphpad performance: library.persist.changed count=%d", changedCount)
        } catch {
            NSLog("Failed to persist app cache: \(error.localizedDescription)")
        }
    }

    private func dedupe(_ apps: [InstalledApplication]) -> [InstalledApplication] {
        var seen = Set<String>()
        return apps.filter { seen.insert($0.id).inserted }
    }

    private func setApps(_ nextApps: [InstalledApplication]) {
        let dedupedApps = dedupe(nextApps)
        var nextIndex: [String: InstalledApplication] = [:]
        for app in dedupedApps where nextIndex[app.id] == nil {
            nextIndex[app.id] = app
        }

        apps = dedupedApps
        appIndex = nextIndex
        rebuildLauncherItems()
    }

    private func rebuildLauncherItems() {
        let folderedIDs = Set(folders.flatMap(\.appBundleIdentifiers))
        let baseItems: [LauncherItem] = folders.map(LauncherItem.folder)
            + apps.filter { !folderedIDs.contains($0.id) }.map(LauncherItem.app)
        let itemsByID = Dictionary(uniqueKeysWithValues: baseItems.map { ($0.id, $0) })
        var usedIDs = Set<String>()

        var orderedItems = layoutOrder.compactMap { id -> LauncherItem? in
            guard let item = itemsByID[id], usedIDs.insert(id).inserted else {
                return nil
            }
            return item
        }
        orderedItems += baseItems.filter { usedIDs.insert($0.id).inserted }

        launcherItems = orderedItems
        persistLayoutIfNeeded(for: orderedItems)
    }

    private func moveItem(draggedItemID: String, before targetItemID: String) -> Bool {
        guard launcherItems.contains(where: { $0.id == targetItemID }) else {
            return false
        }

        return moveItem(draggedItemID: draggedItemID, to: launcherItems.firstIndex { $0.id == targetItemID } ?? launcherItems.count)
    }

    private func moveItem(draggedItemID: String, to targetIndex: Int) -> Bool {
        guard let sourceIndex = launcherItems.firstIndex(where: { $0.id == draggedItemID }) else {
            return false
        }

        var items = launcherItems
        let draggedItem = items.remove(at: sourceIndex)
        let normalizedTargetIndex = sourceIndex < targetIndex ? targetIndex - 1 : targetIndex
        let insertIndex = min(max(normalizedTargetIndex, 0), items.count)
        items.insert(draggedItem, at: insertIndex)

        guard items != launcherItems else {
            return false
        }

        launcherItems = items
        saveCurrentLayout()
        return true
    }

    private func saveCurrentLayout() {
        saveLayout(for: launcherItems)
    }

    private func persistLayoutIfNeeded(for items: [LauncherItem]) {
        let nextLayoutOrder = items.map(\.id)
        guard !nextLayoutOrder.isEmpty, nextLayoutOrder != layoutOrder else {
            return
        }

        saveLayout(for: items)
    }

    private func saveLayout(for items: [LauncherItem]) {
        layoutOrder = items.map(\.id)
        do {
            try layoutRepository?.replaceAll(items.enumerated().map { index, item in
                LauncherLayoutRecord(
                    kind: item.layoutKind,
                    targetIdentifier: item.targetIdentifier,
                    positionIndex: index
                )
            })
        } catch {
            NSLog("Failed to save launcher layout: \(error.localizedDescription)")
        }
    }

    private func appSignature(_ apps: [InstalledApplication]) -> [String] {
        apps.map { "\($0.id)|\($0.displayName)|\($0.url.path)" }.sorted()
    }

    private func startWatchingApplicationDirectories() {
        guard directoryWatcher == nil else {
            return
        }

        directoryWatcher = ApplicationDirectoryWatcher(roots: ApplicationScanner.standardRoots()) { [weak self] in
            Task { @MainActor [weak self] in
                self?.reload(reason: "application-directory-change")
            }
        }
    }

    private static func appID(from layoutID: String) -> String? {
        guard layoutID.hasPrefix("app-") else {
            return nil
        }
        return String(layoutID.dropFirst(4))
    }

    private static func folderID(from layoutID: String) -> UUID? {
        guard layoutID.hasPrefix("folder-") else {
            return nil
        }
        return UUID(uuidString: String(layoutID.dropFirst(7)))
    }

    private static func layoutID(for record: LauncherLayoutRecord) -> String {
        layoutID(kind: record.kind, targetIdentifier: record.targetIdentifier)
    }

    private static func layoutID(kind: LauncherLayoutKind, targetIdentifier: String) -> String {
        switch kind {
        case .app:
            return "app-\(targetIdentifier)"
        case .folder:
            return "folder-\(targetIdentifier)"
        }
    }
}

private enum LauncherItem: Identifiable, Equatable {
    case folder(FolderRecord)
    case app(InstalledApplication)

    var id: String {
        switch self {
        case .folder(let folder):
            "folder-\(folder.id.uuidString)"
        case .app(let app):
            "app-\(app.id)"
        }
    }

    var layoutKind: LauncherLayoutKind {
        switch self {
        case .folder:
            return .folder
        case .app:
            return .app
        }
    }

    var targetIdentifier: String {
        switch self {
        case .folder(let folder):
            return folder.id.uuidString
        case .app(let app):
            return app.id
        }
    }

    var isApp: Bool {
        if case .app = self {
            return true
        }
        return false
    }
}

private struct InstalledApplication: Identifiable, Equatable {
    let id: String
    let url: URL
    let displayName: String
    let bundleIdentifier: String?
    let icon: NSImage

    init(scannedApp: ScannedApplication, iconCache: IconCache) {
        self.id = scannedApp.id
        self.url = scannedApp.url
        self.displayName = scannedApp.displayName
        self.bundleIdentifier = scannedApp.bundleIdentifier
        self.icon = iconCache.icon(for: scannedApp.url)
    }

    init?(record: AppRecord, iconCache: IconCache) {
        guard let executablePath = record.executablePath else {
            return nil
        }

        let url = URL(fileURLWithPath: executablePath)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        self.id = record.bundleIdentifier
        self.url = url
        self.displayName = record.displayName
        self.bundleIdentifier = record.bundleIdentifier
        self.icon = iconCache.icon(for: url)
    }

    static func == (lhs: InstalledApplication, rhs: InstalledApplication) -> Bool {
        lhs.id == rhs.id
    }
}

private final class IconCache {
    private let cache = NSCache<NSURL, NSImage>()

    func icon(for url: URL) -> NSImage {
        let key = url as NSURL
        if let cachedIcon = cache.object(forKey: key) {
            return cachedIcon
        }

        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 128, height: 128)
        cache.setObject(icon, forKey: key)
        return icon
    }
}

private struct ScannedApplication: Sendable {
    let id: String
    let url: URL
    let displayName: String
    let bundleIdentifier: String?

    func appRecord() -> AppRecord {
        AppRecord(
            bundleIdentifier: bundleIdentifier ?? id,
            displayName: displayName,
            executablePath: url.path
        )
    }
}

private struct ApplicationScanner: Sendable {
    static func standardRoots() -> [URL] {
        let fileManager = FileManager.default
        var roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications/Utilities", isDirectory: true)
        ]

        if let userApplications = fileManager.urls(for: .applicationDirectory, in: .userDomainMask).first {
            roots.append(userApplications)
        }

        return roots
    }

    func scan() -> [ScannedApplication] {
        var seenPaths = Set<String>()
        var apps: [ScannedApplication] = []

        for root in scanRoots() {
            for appURL in appBundleURLs(under: root) {
                let normalizedPath = appURL.resolvingSymlinksInPath().path
                guard seenPaths.insert(normalizedPath).inserted else {
                    continue
                }

                guard let app = makeApplication(from: appURL) else {
                    continue
                }

                apps.append(app)
            }
        }

        return apps.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    private func scanRoots() -> [URL] {
        Self.standardRoots()
    }

    private func appBundleURLs(under root: URL) -> [URL] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: root.path) else {
            return []
        }

        let options: FileManager.DirectoryEnumerationOptions = [
            .skipsHiddenFiles,
            .skipsPackageDescendants
        ]

        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
            options: options
        ) else {
            return []
        }

        var urls: [URL] = []

        for case let url as URL in enumerator {
            guard url.pathExtension == "app" else {
                continue
            }

            urls.append(url)
            enumerator.skipDescendants()
        }

        return urls
    }

    private func makeApplication(from url: URL) -> ScannedApplication? {
        guard let bundle = Bundle(url: url) else {
            return nil
        }

        let info = bundle.infoDictionary ?? [:]
        let displayName = info["CFBundleDisplayName"] as? String
            ?? info["CFBundleName"] as? String
            ?? url.deletingPathExtension().lastPathComponent

        let bundleIdentifier = bundle.bundleIdentifier
        let id = bundleIdentifier ?? url.resolvingSymlinksInPath().path

        return ScannedApplication(
            id: id,
            url: url,
            displayName: displayName,
            bundleIdentifier: bundleIdentifier
        )
    }
}

private final class ApplicationDirectoryWatcher: @unchecked Sendable {
    private let queue = DispatchQueue(label: "Glyphpad.ApplicationDirectoryWatcher", qos: .utility)
    private let onChange: @Sendable () -> Void
    private var sources: [DispatchSourceFileSystemObject] = []
    private var debounceWorkItem: DispatchWorkItem?

    init(roots: [URL], onChange: @escaping @Sendable () -> Void) {
        self.onChange = onChange

        for root in roots {
            guard FileManager.default.fileExists(atPath: root.path) else {
                continue
            }

            let fileDescriptor = open(root.path, O_EVTONLY)
            guard fileDescriptor >= 0 else {
                continue
            }

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fileDescriptor,
                eventMask: [.write, .rename, .delete, .extend, .attrib],
                queue: queue
            )

            source.setEventHandler { [weak self] in
                self?.scheduleRefresh()
            }
            source.setCancelHandler {
                close(fileDescriptor)
            }
            sources.append(source)
            source.resume()
        }

        NSLog("Glyphpad performance: app-directory-watcher roots=%d", sources.count)
    }

    deinit {
        debounceWorkItem?.cancel()
        for source in sources {
            source.cancel()
        }
    }

    private func scheduleRefresh() {
        debounceWorkItem?.cancel()

        let onChange = onChange
        let item = DispatchWorkItem {
            onChange()
        }
        debounceWorkItem = item
        queue.asyncAfter(deadline: .now() + 0.8, execute: item)
    }
}
