import AppKit
import GlyphpadCore
import GlyphpadStorage
import SwiftUI

@main
@MainActor
private struct GlyphpadMain {
    private static var delegate: LauncherAppDelegate?

    static func main() {
        let app = NSApplication.shared
        let delegate = LauncherAppDelegate()
        Self.delegate = delegate
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

@MainActor
private final class LauncherAppDelegate: NSObject, NSApplicationDelegate {
    private var window: LauncherWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        NSApplication.shared.presentationOptions = [.autoHideDock, .autoHideMenuBar]
        showLauncher()
    }

    private func showLauncher() {
        let screen = NSScreen.main ?? NSScreen.screens.first
        let frame = screen?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let window = LauncherWindow(contentRect: frame)
        window.dismissHandler = { [weak self] in self?.dismissLauncher() }

        let settingsController = LauncherSettingsController()
        let rootView = LauncherView(settingsController: settingsController) { [weak self] in
            self?.dismissLauncher()
        }

        window.contentView = NSHostingView(rootView: rootView)
        window.setFrame(frame, display: true)
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
        }
    }

    private func dismissLauncher() {
        guard let window else {
            NSApplication.shared.terminate(nil)
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0
        } completionHandler: {
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
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

        super.keyDown(with: event)
    }
}

private struct LauncherView: View {
    @ObservedObject var settingsController: LauncherSettingsController
    let onDismiss: () -> Void

    @StateObject private var library = ApplicationLibrary()
    @State private var searchText = ""
    @State private var showsSettings = false
    @State private var openFolder: FolderRecord?
    @State private var visible = false

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
                DesktopBackdrop()
                    .onTapGesture {
                        dismiss()
                    }

                VStack(spacing: 30) {
                    HStack {
                        Spacer()

                        SearchField(text: $searchText)

                        Spacer()

                        Button {
                            showsSettings.toggle()
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.86))
                                .frame(width: 46, height: 46)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay {
                                    Circle()
                                        .stroke(.white.opacity(0.16), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                        .help("Settings")
                    }
                    .padding(.horizontal, 54)
                    .padding(.top, max(42, proxy.safeAreaInsets.top + 28))

                    launcherContent(maxSize: proxy.size)

                    PageDots()
                        .padding(.bottom, max(28, proxy.safeAreaInsets.bottom + 18))
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .scaleEffect(visible ? 1 : 0.985)
                .opacity(visible ? 1 : 0)
                .animation(.easeOut(duration: 0.18), value: visible)

                if showsSettings {
                    SettingsPanel(controller: settingsController)
                        .padding(.top, max(100, proxy.safeAreaInsets.top + 84))
                        .padding(.trailing, 54)
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topTrailing)
                        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .topTrailing)))
                }

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
            .animation(.easeOut(duration: 0.16), value: showsSettings)
            .animation(.easeOut(duration: 0.18), value: openFolder?.id)
        }
        .ignoresSafeArea()
        .focusable()
        .onAppear {
            library.reload()
            visible = true
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
        visible = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            onDismiss()
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

private struct SettingsPanel: View {
    @ObservedObject var controller: LauncherSettingsController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Layout")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

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
        .toggleStyle(.switch)
        .foregroundStyle(.white)
        .controlSize(.regular)
        .padding(18)
        .frame(width: 292)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.32), radius: 22, x: 0, y: 14)
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
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(.white)
            Circle().fill(.white.opacity(0.35))
        }
        .frame(width: 30, height: 8)
    }
}

private struct DesktopBackdrop: View {
    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.54),
                    Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.68),
                    Color.black.opacity(0.58)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
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
private final class ApplicationLibrary: ObservableObject {
    @Published private(set) var apps: [InstalledApplication] = []
    @Published private(set) var folders: [FolderRecord] = []

    private let iconCache = IconCache()
    private let appRepository: SQLiteAppRepository?
    private let folderRepository: SQLiteFolderRepository?
    private var refreshTask: Task<Void, Never>?

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

    func reload() {
        loadFolders()
        loadCachedApps()
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            let scannedApps = await Task.detached(priority: .userInitiated) {
                ApplicationScanner().scan()
            }.value

            guard !Task.isCancelled else {
                return
            }

            self?.publish(scannedApps)
            self?.persist(scannedApps)
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
        var appByID: [String: InstalledApplication] = [:]
        for app in apps where appByID[app.id] == nil {
            appByID[app.id] = app
        }
        return folder.appBundleIdentifiers.compactMap { appByID[$0] }
    }

    func createFolder(sourceAppID: String, targetAppID: String) -> FolderRecord? {
        guard sourceAppID != targetAppID else {
            return nil
        }
        guard folderRepository != nil else {
            return nil
        }
        guard apps.contains(where: { $0.id == sourceAppID }), apps.contains(where: { $0.id == targetAppID }) else {
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
                apps = cachedApps
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
        apps = dedupe(scannedApps.map { app in
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
