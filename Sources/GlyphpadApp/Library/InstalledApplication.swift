import AppKit
import Foundation
import GlyphpadCore

struct InstalledApplication: Identifiable, Equatable {
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

final class IconCache {
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
