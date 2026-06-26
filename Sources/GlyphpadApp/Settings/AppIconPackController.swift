import AppKit
import Foundation
import GlyphpadCore
import GlyphpadStorage

@MainActor
final class AppIconPackController: ObservableObject {
    @Published private(set) var overrides: [AppIconOverrideRecord] = []
    @Published private(set) var isImporting = false
    @Published private(set) var lastResult: AppIconPackImportResult?

    private let repository: SQLiteAppIconOverrideRepository?
    private let importer: AppIconPackImporter

    init() {
        do {
            let store = try AppStoreFactory.makeStore()
            self.repository = store.appIconOverrideRepository()
        } catch {
            NSLog("Failed to open icon override store: \(error.localizedDescription)")
            self.repository = nil
        }
        self.importer = AppIconPackImporter()
        load()
    }

    func load() {
        do {
            overrides = try repository?.fetchAll() ?? []
        } catch {
            NSLog("Failed to load icon overrides: \(error.localizedDescription)")
            overrides = []
        }
    }

    func importIconPack(from url: URL) {
        guard let repository else {
            lastResult = AppIconPackImportResult(importedCount: 0, scannedImageCount: 0, sourceName: url.lastPathComponent)
            return
        }

        isImporting = true
        defer { isImporting = false }

        do {
            let apps = ApplicationScanner().scan()
            let result = try importer.importIconPack(from: url, matching: apps)
            for record in result.records {
                try repository.upsert(record)
            }
            overrides = try repository.fetchAll()
            lastResult = AppIconPackImportResult(
                importedCount: result.records.count,
                scannedImageCount: result.scannedImageCount,
                sourceName: result.sourceName
            )
        } catch {
            NSLog("Failed to import icon pack: \(error.localizedDescription)")
            lastResult = AppIconPackImportResult(importedCount: 0, scannedImageCount: 0, sourceName: url.lastPathComponent)
        }
    }

    func clearImportedIcons() {
        do {
            try repository?.deleteAll()
            overrides = []
            lastResult = nil
        } catch {
            NSLog("Failed to clear icon overrides: \(error.localizedDescription)")
        }
    }
}

struct AppIconPackImportResult: Equatable {
    let importedCount: Int
    let scannedImageCount: Int
    let sourceName: String
}

struct AppIconPackImporter {
    struct ImportedPack {
        let records: [AppIconOverrideRecord]
        let scannedImageCount: Int
        let sourceName: String
    }

    private let supportedImageExtensions = Set(["icns", "png", "jpg", "jpeg", "tif", "tiff", "webp"])

    func importIconPack(from sourceURL: URL, matching apps: [ScannedApplication]) throws -> ImportedPack {
        let fileManager = FileManager.default
        let sourceName = sourceURL.deletingPathExtension().lastPathComponent
        let workingDirectory = try preparedWorkingDirectory(for: sourceURL, fileManager: fileManager)
        defer {
            if workingDirectory.isTemporary {
                try? fileManager.removeItem(at: workingDirectory.url)
            }
        }
        let imageURLs = iconImageURLs(under: workingDirectory.url, fileManager: fileManager)
        let imageIndex = imageURLs.reduce(into: [String: URL]()) { partialResult, url in
            let key = normalized(url.deletingPathExtension().lastPathComponent)
            if partialResult[key] == nil {
                partialResult[key] = url
            }
        }
        let destinationDirectory = try iconPackDestinationDirectory(sourceName: sourceName, fileManager: fileManager)

        var records: [AppIconOverrideRecord] = []
        var usedImagePaths = Set<String>()

        for app in apps {
            guard let matchedURL = matchIcon(for: app, in: imageIndex),
                  usedImagePaths.insert(matchedURL.path).inserted else {
                continue
            }

            let destinationURL = destinationDirectory
                .appendingPathComponent(app.id)
                .appendingPathExtension(matchedURL.pathExtension)
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: matchedURL, to: destinationURL)
            records.append(
                AppIconOverrideRecord(
                    appBundleIdentifier: app.id,
                    iconPath: destinationURL.path,
                    sourceName: sourceName
                )
            )
        }

        return ImportedPack(records: records, scannedImageCount: imageURLs.count, sourceName: sourceName)
    }

    private func preparedWorkingDirectory(for sourceURL: URL, fileManager: FileManager) throws -> WorkingDirectory {
        if sourceURL.pathExtension.localizedCaseInsensitiveCompare("zip") == .orderedSame {
            let unzipDirectory = fileManager.temporaryDirectory
                .appendingPathComponent("GlyphpadIconPack-\(UUID().uuidString)", isDirectory: true)
            try fileManager.createDirectory(at: unzipDirectory, withIntermediateDirectories: true)
            try unzip(sourceURL, to: unzipDirectory)
            return WorkingDirectory(url: unzipDirectory, isTemporary: true)
        }

        return WorkingDirectory(url: sourceURL, isTemporary: false)
    }

    private func iconImageURLs(under root: URL, fileManager: FileManager) -> [URL] {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory) else {
            return []
        }

        if !isDirectory.boolValue {
            return isSupportedImage(root) ? [root] : []
        }

        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { entry -> URL? in
            guard let url = entry as? URL, isSupportedImage(url) else {
                return nil
            }
            return url
        }
    }

    private func isSupportedImage(_ url: URL) -> Bool {
        supportedImageExtensions.contains(url.pathExtension.lowercased())
    }

    private func matchIcon(
        for app: ScannedApplication,
        in imageIndex: [String: URL]
    ) -> URL? {
        let candidates = [
            app.bundleIdentifier,
            app.id,
            app.displayName,
            app.url.deletingPathExtension().lastPathComponent
        ]
        .compactMap { $0 }
        .map(normalized)

        for candidate in candidates {
            if let match = imageIndex[candidate] {
                return match
            }
        }

        return nil
    }

    private func normalized(_ value: String) -> String {
        value
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    private func iconPackDestinationDirectory(sourceName: String, fileManager: FileManager) throws -> URL {
        let baseDirectory = try AppStoreFactory.applicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent("IconPacks", isDirectory: true)
        let directory = baseDirectory
            .appendingPathComponent(slug(sourceName))
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func slug(_ value: String) -> String {
        let slug = value
            .lowercased()
            .map { $0.isLetter || $0.isNumber ? String($0) : "-" }
            .joined()
            .split(separator: "-")
            .joined(separator: "-")
        return slug.isEmpty ? "icon-pack" : slug
    }

    private func unzip(_ sourceURL: URL, to destinationURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", sourceURL.path, destinationURL.path]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    private struct WorkingDirectory {
        let url: URL
        let isTemporary: Bool
    }
}
