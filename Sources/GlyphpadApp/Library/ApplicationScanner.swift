import AppKit
import Darwin
import Foundation
import GlyphpadCore

struct ScannedApplication: Sendable {
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

struct ApplicationScanner: Sendable {
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

final class ApplicationDirectoryWatcher: @unchecked Sendable {
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
