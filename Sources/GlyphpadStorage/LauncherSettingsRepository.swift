import GlyphpadCore

public protocol LauncherSettingsRepository: Sendable {
    func load() throws -> LauncherSettings
    func save(_ settings: LauncherSettings) throws
}
