import Foundation

public struct AppIconOverrideRecord: Equatable, Identifiable, Sendable {
    public var id: String { appBundleIdentifier }

    public var appBundleIdentifier: String
    public var iconPath: String
    public var sourceName: String
    public var updatedAt: Date

    public init(
        appBundleIdentifier: String,
        iconPath: String,
        sourceName: String,
        updatedAt: Date = Date()
    ) {
        self.appBundleIdentifier = appBundleIdentifier
        self.iconPath = iconPath
        self.sourceName = sourceName
        self.updatedAt = updatedAt
    }
}
