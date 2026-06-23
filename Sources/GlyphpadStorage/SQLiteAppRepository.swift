import Foundation
import GlyphpadCore

public final class SQLiteAppRepository: AppRepository, @unchecked Sendable {
    private let database: SQLiteDatabase
    private let dateFormatter = ISO8601DateFormatter()

    init(database: SQLiteDatabase) {
        self.database = database
    }

    public func upsert(_ app: AppRecord) throws {
        let statement = try database.prepare(
            """
            INSERT INTO apps (
                id,
                bundle_identifier,
                display_name,
                executable_path,
                category_id,
                discovered_at,
                updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(bundle_identifier) DO UPDATE SET
                display_name = excluded.display_name,
                executable_path = excluded.executable_path,
                category_id = excluded.category_id,
                updated_at = excluded.updated_at;
            """
        )

        try bind(app, to: statement)
        _ = try statement.step()
    }

    public func fetchAll() throws -> [AppRecord] {
        let statement = try database.prepare(
            """
            SELECT id, bundle_identifier, display_name, executable_path, category_id, discovered_at, updated_at
            FROM apps
            ORDER BY display_name COLLATE NOCASE ASC;
            """
        )

        var apps: [AppRecord] = []
        while try statement.step() {
            apps.append(try decodeApp(from: statement))
        }
        return apps
    }

    public func fetch(bundleIdentifier: String) throws -> AppRecord? {
        let statement = try database.prepare(
            """
            SELECT id, bundle_identifier, display_name, executable_path, category_id, discovered_at, updated_at
            FROM apps
            WHERE bundle_identifier = ?
            LIMIT 1;
            """
        )

        try statement.bind(bundleIdentifier, at: 1)

        guard try statement.step() else {
            return nil
        }

        return try decodeApp(from: statement)
    }

    private func bind(_ app: AppRecord, to statement: SQLiteStatement) throws {
        try statement.bind(app.id.uuidString, at: 1)
        try statement.bind(app.bundleIdentifier, at: 2)
        try statement.bind(app.displayName, at: 3)
        try statement.bind(app.executablePath, at: 4)
        try statement.bind(app.categoryID?.uuidString, at: 5)
        try statement.bind(dateFormatter.string(from: app.discoveredAt), at: 6)
        try statement.bind(dateFormatter.string(from: app.updatedAt), at: 7)
    }

    private func decodeApp(from statement: SQLiteStatement) throws -> AppRecord {
        guard let id = UUID(uuidString: try statement.string(at: 0)) else {
            throw SQLiteError.invalidColumn("Invalid app id")
        }

        let categoryID = statement.optionalString(at: 4).flatMap(UUID.init(uuidString:))

        guard let discoveredAt = dateFormatter.date(from: try statement.string(at: 5)) else {
            throw SQLiteError.invalidColumn("Invalid discovered_at")
        }

        guard let updatedAt = dateFormatter.date(from: try statement.string(at: 6)) else {
            throw SQLiteError.invalidColumn("Invalid updated_at")
        }

        return AppRecord(
            id: id,
            bundleIdentifier: try statement.string(at: 1),
            displayName: try statement.string(at: 2),
            executablePath: statement.optionalString(at: 3),
            categoryID: categoryID,
            discoveredAt: discoveredAt,
            updatedAt: updatedAt
        )
    }
}
