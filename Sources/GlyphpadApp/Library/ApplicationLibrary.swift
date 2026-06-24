import AppKit
import Combine
import Foundation
import GlyphpadCore
import GlyphpadStorage

@MainActor
final class ApplicationLibrary: ObservableObject, @unchecked Sendable {
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

    func handleInternalDrop(
        draggedItemID: String,
        sourceFolderID: UUID?,
        targetItemID: String,
        shouldCreateFolder: Bool,
        placement: LauncherDropPlacement
    ) -> Bool {
        guard draggedItemID != targetItemID else {
            return false
        }

        if let sourceFolderID,
           let draggedAppID = Self.appID(from: draggedItemID) {
            return moveAppOutOfFolder(
                appID: draggedAppID,
                sourceFolderID: sourceFolderID,
                targetItemID: targetItemID,
                placement: placement
            )
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

        guard let targetIndex = launcherItems.firstIndex(where: { $0.id == targetItemID }) else {
            return false
        }

        switch placement {
        case .before:
            return moveItem(draggedItemID: draggedItemID, to: targetIndex)
        case .after:
            return moveItem(draggedItemID: draggedItemID, to: targetIndex + 1)
        }
    }

    func moveAppOutOfFolder(draggedItemID: String, sourceFolderID: UUID) -> Bool {
        guard let draggedAppID = Self.appID(from: draggedItemID) else {
            return false
        }

        return moveAppOutOfFolderToTopLevel(
            appID: draggedAppID,
            sourceFolderID: sourceFolderID,
            targetItemID: nil,
            placement: .after
        )
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
            try writeFolderMembers(folderID: folderID, appBundleIdentifiers: folder.appBundleIdentifiers + [appID])
            loadFolders()
            rebuildLauncherItems()
            saveCurrentLayout()
            return true
        } catch {
            NSLog("Failed to add app to folder: \(error.localizedDescription)")
            return false
        }
    }

    private func moveAppOutOfFolder(
        appID: String,
        sourceFolderID: UUID,
        targetItemID: String,
        placement: LauncherDropPlacement
    ) -> Bool {
        guard folderRepository != nil else {
            return false
        }
        guard appIndex[appID] != nil else {
            return false
        }
        guard let sourceFolder = folder(id: sourceFolderID),
              sourceFolder.appBundleIdentifiers.contains(appID) else {
            return false
        }

        if let targetFolderID = Self.folderID(from: targetItemID) {
            guard targetFolderID != sourceFolderID,
                  let targetFolder = folder(id: targetFolderID),
                  !targetFolder.appBundleIdentifiers.contains(appID) else {
                return false
            }

            do {
                try writeFolderMembers(
                    folderID: sourceFolderID,
                    appBundleIdentifiers: sourceFolder.appBundleIdentifiers.filter { $0 != appID }
                )
                try writeFolderMembers(
                    folderID: targetFolderID,
                    appBundleIdentifiers: targetFolder.appBundleIdentifiers + [appID]
                )
                loadFolders()
                rebuildLauncherItems()
                saveCurrentLayout()
                return true
            } catch {
                NSLog("Failed to move app between folders: \(error.localizedDescription)")
                return false
            }
        }

        guard launcherItems.contains(where: { $0.id == targetItemID }) else {
            return false
        }

        return moveAppOutOfFolderToTopLevel(
            appID: appID,
            sourceFolderID: sourceFolderID,
            targetItemID: targetItemID,
            placement: placement
        )
    }

    private func moveAppOutOfFolderToTopLevel(
        appID: String,
        sourceFolderID: UUID,
        targetItemID: String?,
        placement: LauncherDropPlacement
    ) -> Bool {
        guard folderRepository != nil else {
            return false
        }
        guard appIndex[appID] != nil else {
            return false
        }
        guard let sourceFolder = folder(id: sourceFolderID),
              sourceFolder.appBundleIdentifiers.contains(appID) else {
            return false
        }

        do {
            try writeFolderMembers(
                folderID: sourceFolderID,
                appBundleIdentifiers: sourceFolder.appBundleIdentifiers.filter { $0 != appID }
            )
            loadFolders()
            rebuildLauncherItems()

            let fallbackTargetID = Self.layoutID(kind: .folder, targetIdentifier: sourceFolderID.uuidString)
            guard let targetIndex = launcherItems.firstIndex(where: { $0.id == (targetItemID ?? fallbackTargetID) }) else {
                saveCurrentLayout()
                return true
            }

            let insertIndex: Int
            switch placement {
            case .before:
                insertIndex = targetIndex
            case .after:
                insertIndex = targetIndex + 1
            }

            return moveItem(
                draggedItemID: Self.layoutID(kind: .app, targetIdentifier: appID),
                to: insertIndex
            )
        } catch {
            NSLog("Failed to move app out of folder: \(error.localizedDescription)")
            return false
        }
    }

    private func writeFolderMembers(folderID: UUID, appBundleIdentifiers: [String]) throws {
        if appBundleIdentifiers.isEmpty {
            try folderRepository?.delete(folderID: folderID)
        } else {
            try folderRepository?.updateMembers(
                folderID: folderID,
                appBundleIdentifiers: appBundleIdentifiers
            )
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
