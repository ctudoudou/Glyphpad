import Foundation
import GlyphpadCore

public final class SQLiteAppIconOverrideRepository: AppIconOverrideRepository, @unchecked Sendable {
    private let database: SQLiteDatabase
    private let dateFormatter = ISO8601DateFormatter()

    init(database: SQLiteDatabase) {
        self.database = database
    }

    public func fetchAll() throws -> [AppIconOverrideRecord] {
        let statement = try database.prepare(
            """
            SELECT app_bundle_identifier, icon_path, source_name, updated_at
            FROM app_icon_overrides
            ORDER BY app_bundle_identifier COLLATE NOCASE ASC;
            """
        )

        var overrides: [AppIconOverrideRecord] = []
        while try statement.step() {
            overrides.append(try decodeOverride(from: statement))
        }
        return overrides
    }

    public func upsert(_ override: AppIconOverrideRecord) throws {
        let statement = try database.prepare(
            """
            INSERT INTO app_icon_overrides (
                app_bundle_identifier,
                icon_path,
                source_name,
                updated_at
            )
            VALUES (?, ?, ?, ?)
            ON CONFLICT(app_bundle_identifier) DO UPDATE SET
                icon_path = excluded.icon_path,
                source_name = excluded.source_name,
                updated_at = excluded.updated_at;
            """
        )

        try statement.bind(override.appBundleIdentifier, at: 1)
        try statement.bind(override.iconPath, at: 2)
        try statement.bind(override.sourceName, at: 3)
        try statement.bind(dateFormatter.string(from: override.updatedAt), at: 4)
        _ = try statement.step()
    }

    public func delete(bundleIdentifier: String) throws {
        let statement = try database.prepare(
            """
            DELETE FROM app_icon_overrides
            WHERE app_bundle_identifier = ?;
            """
        )
        try statement.bind(bundleIdentifier, at: 1)
        _ = try statement.step()
    }

    public func deleteAll() throws {
        try database.execute("DELETE FROM app_icon_overrides;")
    }

    private func decodeOverride(from statement: SQLiteStatement) throws -> AppIconOverrideRecord {
        guard let updatedAt = dateFormatter.date(from: try statement.string(at: 3)) else {
            throw SQLiteError.invalidColumn("Invalid updated_at")
        }

        return AppIconOverrideRecord(
            appBundleIdentifier: try statement.string(at: 0),
            iconPath: try statement.string(at: 1),
            sourceName: try statement.string(at: 2),
            updatedAt: updatedAt
        )
    }
}
