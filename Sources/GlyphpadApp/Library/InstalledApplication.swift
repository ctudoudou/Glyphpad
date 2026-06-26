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
        self.icon = iconCache.icon(for: scannedApp.url, appID: scannedApp.id)
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
        self.icon = iconCache.icon(for: url, appID: record.bundleIdentifier)
    }

    static func == (lhs: InstalledApplication, rhs: InstalledApplication) -> Bool {
        lhs.id == rhs.id
    }
}

final class IconCache {
    private let cache = NSCache<NSString, NSImage>()
    private var iconOverrides: [String: String] = [:]

    func updateOverrides(_ overrides: [AppIconOverrideRecord]) {
        let nextOverrides = Dictionary(uniqueKeysWithValues: overrides.map { ($0.appBundleIdentifier, $0.iconPath) })
        guard nextOverrides != iconOverrides else {
            return
        }

        iconOverrides = nextOverrides
        cache.removeAllObjects()
    }

    func icon(for url: URL, appID: String) -> NSImage {
        let overridePath = iconOverrides[appID]
        let key = "\(url.path)|\(overridePath ?? "system")" as NSString
        if let cachedIcon = cache.object(forKey: key) {
            return cachedIcon
        }

        if let overridePath,
           let overrideIcon = NSImage(contentsOfFile: overridePath) {
            overrideIcon.size = NSSize(width: 128, height: 128)
            cache.setObject(overrideIcon, forKey: key)
            return overrideIcon
        }

        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 128, height: 128)
        cache.setObject(icon, forKey: key)
        return icon
    }
}
