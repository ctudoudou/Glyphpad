import Foundation
import GlyphpadCore

public final class SQLiteLauncherSettingsRepository: LauncherSettingsRepository, @unchecked Sendable {
    private let database: SQLiteDatabase
    private let dateFormatter = ISO8601DateFormatter()

    init(database: SQLiteDatabase) {
        self.database = database
    }

    public func load() throws -> LauncherSettings {
        let statement = try database.prepare(
            """
            SELECT
                columns,
                rows,
                icon_size,
                auto_arrange,
                navigation_mode,
                background_image_path,
                background_blur_radius,
                api_endpoint,
                api_key
            FROM launcher_settings
            WHERE id = 'default'
            LIMIT 1;
            """
        )

        guard try statement.step() else {
            return .default
        }

        let navigationMode = LauncherNavigationMode(rawValue: try statement.string(at: 4)) ?? .verticalScroll

        return LauncherSettings(
            columns: statement.int(at: 0),
            rows: statement.int(at: 1),
            iconSize: CGFloat(statement.double(at: 2)),
            autoArrange: statement.int(at: 3) != 0,
            navigationMode: navigationMode,
            backgroundImagePath: statement.optionalString(at: 5),
            backgroundBlurRadius: CGFloat(statement.double(at: 6)),
            apiEndpoint: statement.optionalString(at: 7),
            apiKey: statement.optionalString(at: 8)
        ).clamped()
    }

    public func save(_ settings: LauncherSettings) throws {
        let clamped = settings.clamped()
        let statement = try database.prepare(
            """
            INSERT INTO launcher_settings (
                id,
                columns,
                rows,
                icon_size,
                auto_arrange,
                navigation_mode,
                background_image_path,
                background_blur_radius,
                api_endpoint,
                api_key,
                updated_at
            )
            VALUES ('default', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                columns = excluded.columns,
                rows = excluded.rows,
                icon_size = excluded.icon_size,
                auto_arrange = excluded.auto_arrange,
                navigation_mode = excluded.navigation_mode,
                background_image_path = excluded.background_image_path,
                background_blur_radius = excluded.background_blur_radius,
                api_endpoint = excluded.api_endpoint,
                api_key = excluded.api_key,
                updated_at = excluded.updated_at;
            """
        )

        try statement.bind(clamped.columns, at: 1)
        try statement.bind(clamped.rows, at: 2)
        try statement.bind(Double(clamped.iconSize), at: 3)
        try statement.bind(clamped.autoArrange ? 1 : 0, at: 4)
        try statement.bind(clamped.navigationMode.rawValue, at: 5)
        try statement.bind(clamped.backgroundImagePath, at: 6)
        try statement.bind(Double(clamped.backgroundBlurRadius), at: 7)
        try statement.bind(clamped.apiEndpoint, at: 8)
        try statement.bind(clamped.apiKey, at: 9)
        try statement.bind(dateFormatter.string(from: Date()), at: 10)
        _ = try statement.step()
    }
}
