import AppKit
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

    func applicationDidFinishLaunching(_ notification: Notification) {
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

    private func showLauncher() {
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
            NSApplication.shared.terminate(nil)
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0
        } completionHandler: {
            DispatchQueue.main.async {
                PerformanceLog.finish("launcher.close", startedAt: startedAt)
                self.window = nil
                if self.settingsWindow?.isVisible == true {
                    return
                }
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func showSettingsWindow() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 620),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "Glyphpad Settings"
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.delegate = self
        settingsWindow.level = .glyphpadSettingsPanel
        settingsWindow.center()
        settingsWindow.contentView = NSHostingView(rootView: SettingsWindowView(controller: settingsController))
        settingsWindow.makeKeyAndOrderFront(nil)
        self.settingsWindow = settingsWindow
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow, closingWindow === settingsWindow else {
            return
        }

        settingsWindow = nil
        if window == nil {
            NSApplication.shared.terminate(nil)
        }
    }
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
}

private extension NSWindow.Level {
    static let glyphpadSettingsPanel = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
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
        persist()
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

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Glyphpad Settings")
                .font(.system(size: 24, weight: .semibold))

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    settingsSection("Launcher") {
                        Toggle("Auto arrange", isOn: Binding(
                            get: { controller.settings.autoArrange },
                            set: { value in controller.update { $0.autoArrange = value } }
                        ))

                        Stepper(value: Binding(
                            get: { controller.settings.columns },
                            set: { value in controller.update { $0.columns = value } }
                        ), in: 4...12) {
                            SettingValueLabel(title: "Columns", value: "\(controller.settings.clampedColumns)")
                        }
                        .disabled(controller.settings.autoArrange)

                        Stepper(value: Binding(
                            get: { controller.settings.rows },
                            set: { value in controller.update { $0.rows = value } }
                        ), in: 3...8) {
                            SettingValueLabel(title: "Rows", value: "\(controller.settings.clampedRows)")
                        }
                        .disabled(controller.settings.autoArrange)

                        VStack(alignment: .leading, spacing: 8) {
                            SettingValueLabel(title: "Icon size", value: "\(Int(controller.settings.clampedIconSize))")

                            Slider(value: Binding(
                                get: { Double(controller.settings.iconSize) },
                                set: { value in controller.update { $0.iconSize = CGFloat(value) } }
                            ), in: 48...112, step: 2)
                        }

                        Picker("Navigation", selection: Binding(
                            get: { controller.settings.navigationMode },
                            set: { value in controller.update { $0.navigationMode = value } }
                        )) {
                            Text("Vertical").tag(LauncherNavigationMode.verticalScroll)
                            Text("Pages").tag(LauncherNavigationMode.horizontalPages)
                        }
                        .pickerStyle(.segmented)
                    }

                    settingsSection("Background") {
                        HStack(spacing: 10) {
                            Button("Choose Image") {
                                chooseBackgroundImage()
                            }

                            Button("Clear") {
                                controller.update { $0.backgroundImagePath = nil }
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

                        VStack(alignment: .leading, spacing: 8) {
                            SettingValueLabel(
                                title: "Blur",
                                value: "\(Int(controller.settings.clampedBackgroundBlurRadius))"
                            )

                            Slider(value: Binding(
                                get: { Double(controller.settings.backgroundBlurRadius) },
                                set: { value in controller.update { $0.backgroundBlurRadius = CGFloat(value) } }
                            ), in: 0...48, step: 1)
                        }
                    }

                    settingsSection("API") {
                        TextField("Endpoint", text: Binding(
                            get: { controller.settings.apiEndpoint ?? "" },
                            set: { value in controller.update { $0.apiEndpoint = value } }
                        ))
                        .textFieldStyle(.roundedBorder)

                        SecureField("API Key", text: Binding(
                            get: { controller.settings.apiKey ?? "" },
                            set: { value in controller.update { $0.apiKey = value } }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.trailing, 8)
            }
        }
        .toggleStyle(.switch)
        .controlSize(.regular)
        .padding(24)
        .frame(width: 560, height: 620)
    }

    @ViewBuilder
    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
        Divider()
    }

    private func chooseBackgroundImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        if panel.runModal() == .OK, let url = panel.url {
            controller.update { $0.backgroundImagePath = url.path }
        }
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
    let launch: (InstalledApplication) -> Void

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
            LazyHStack(spacing: 0) {
                ForEach(Array(pages.enumerated()), id: \.offset) { _, page in
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
                }
            }
        }
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
        switch item {
        case .app(let app):
            AppTile(app: app, settings: settings) {
                launch(app)
            }
            .draggable(app.id)
            .dropDestination(for: String.self) { draggedIDs, _ in
                guard let draggedID = draggedIDs.first else {
                    return false
                }
                return library.createFolder(sourceAppID: draggedID, targetAppID: app.id) != nil
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

private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))

            TextField("Search", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .frame(width: 420, height: 46)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.20), lineWidth: 1)
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

    private let iconCache = IconCache()
    private let appRepository: SQLiteAppRepository?
    private let folderRepository: SQLiteFolderRepository?
    private var refreshTask: Task<Void, Never>?
    private var directoryWatcher: ApplicationDirectoryWatcher?
    private var appIndex: [String: InstalledApplication] = [:]

    init() {
        do {
            let store = try AppStoreFactory.makeStore()
            self.appRepository = store.appRepository()
            self.folderRepository = store.folderRepository()
        } catch {
            NSLog("Failed to open app cache store: \(error.localizedDescription)")
            self.appRepository = nil
            self.folderRepository = nil
        }
    }

    var launcherItems: [LauncherItem] {
        let folderedIDs = Set(folders.flatMap(\.appBundleIdentifiers))
        let visibleApps = apps.filter { !folderedIDs.contains($0.id) }
        return folders.map(LauncherItem.folder) + visibleApps.map(LauncherItem.app)
    }

    func reload(reason: String = "manual") {
        startWatchingApplicationDirectories()
        let reloadStartedAt = PerformanceLog.start()

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
            let folder = try folderRepository?.create(
                name: "Untitled Folder",
                appBundleIdentifiers: [targetAppID, sourceAppID],
                positionIndex: folders.count
            )
            loadFolders()
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
        } catch {
            NSLog("Failed to load folders: \(error.localizedDescription)")
        }
    }

    private func publish(_ scannedApps: [ScannedApplication]) {
        setApps(scannedApps.map { app in
            InstalledApplication(scannedApp: app, iconCache: iconCache)
        })
    }

    private func persist(_ scannedApps: [ScannedApplication]) {
        guard let appRepository else {
            return
        }

        do {
            for app in scannedApps {
                try appRepository.upsert(app.appRecord())
            }
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
