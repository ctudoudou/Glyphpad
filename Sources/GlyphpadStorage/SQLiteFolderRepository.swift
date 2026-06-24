import Foundation
import GlyphpadCore

public final class SQLiteFolderRepository: FolderRepository, @unchecked Sendable {
    private let database: SQLiteDatabase
    private let dateFormatter = ISO8601DateFormatter()

    init(database: SQLiteDatabase) {
        self.database = database
    }

    public func fetchAll() throws -> [FolderRecord] {
        let folderStatement = try database.prepare(
            """
            SELECT id, name, page_index, position_index, updated_at
            FROM folders
            ORDER BY page_index ASC, position_index ASC, name COLLATE NOCASE ASC;
            """
        )

        var folders: [FolderRecord] = []
        while try folderStatement.step() {
            let idString = try folderStatement.string(at: 0)
            guard let id = UUID(uuidString: idString) else {
                throw SQLiteError.invalidColumn("Invalid folder id")
            }

            let updatedAtString = try folderStatement.string(at: 4)
            let updatedAt = dateFormatter.date(from: updatedAtString) ?? Date(timeIntervalSince1970: 0)
            let members = try fetchMembers(folderID: id)

            folders.append(
                FolderRecord(
                    id: id,
                    name: try folderStatement.string(at: 1),
                    appBundleIdentifiers: members,
                    pageIndex: folderStatement.int(at: 2),
                    positionIndex: folderStatement.int(at: 3),
                    updatedAt: updatedAt
                )
            )
        }

        return folders
    }

    public func create(name: String, appBundleIdentifiers: [String], positionIndex: Int) throws -> FolderRecord {
        let now = Date()
        let folder = FolderRecord(
            name: name,
            appBundleIdentifiers: dedupe(appBundleIdentifiers),
            positionIndex: positionIndex,
            updatedAt: now
        )

        try database.execute("BEGIN TRANSACTION;")
        do {
            let folderStatement = try database.prepare(
                """
                INSERT INTO folders (id, name, page_index, position_index, updated_at)
                VALUES (?, ?, ?, ?, ?);
                """
            )
            try folderStatement.bind(folder.id.uuidString, at: 1)
            try folderStatement.bind(folder.name, at: 2)
            try folderStatement.bind(folder.pageIndex, at: 3)
            try folderStatement.bind(folder.positionIndex, at: 4)
            try folderStatement.bind(dateFormatter.string(from: folder.updatedAt), at: 5)
            _ = try folderStatement.step()

            try saveMembers(folderID: folder.id, appBundleIdentifiers: folder.appBundleIdentifiers)
            try database.execute("COMMIT;")
            return folder
        } catch {
            try? database.execute("ROLLBACK;")
            throw error
        }
    }

    public func rename(folderID: UUID, name: String) throws {
        let statement = try database.prepare(
            """
            UPDATE folders
            SET name = ?, updated_at = ?
            WHERE id = ?;
            """
        )

        try statement.bind(name, at: 1)
        try statement.bind(dateFormatter.string(from: Date()), at: 2)
        try statement.bind(folderID.uuidString, at: 3)
        _ = try statement.step()
    }

    public func updateMembers(folderID: UUID, appBundleIdentifiers: [String]) throws {
        try database.execute("BEGIN TRANSACTION;")
        do {
            let folderStatement = try database.prepare(
                """
                UPDATE folders
                SET updated_at = ?
                WHERE id = ?;
                """
            )
            try folderStatement.bind(dateFormatter.string(from: Date()), at: 1)
            try folderStatement.bind(folderID.uuidString, at: 2)
            _ = try folderStatement.step()

            let deleteStatement = try database.prepare(
                """
                DELETE FROM folder_members
                WHERE folder_id = ?;
                """
            )
            try deleteStatement.bind(folderID.uuidString, at: 1)
            _ = try deleteStatement.step()

            try saveMembers(folderID: folderID, appBundleIdentifiers: dedupe(appBundleIdentifiers))
            try database.execute("COMMIT;")
        } catch {
            try? database.execute("ROLLBACK;")
            throw error
        }
    }

    private func fetchMembers(folderID: UUID) throws -> [String] {
        let statement = try database.prepare(
            """
            SELECT app_bundle_identifier
            FROM folder_members
            WHERE folder_id = ?
            ORDER BY sort_order ASC;
            """
        )

        try statement.bind(folderID.uuidString, at: 1)

        var members: [String] = []
        while try statement.step() {
            members.append(try statement.string(at: 0))
        }
        return members
    }

    private func saveMembers(folderID: UUID, appBundleIdentifiers: [String]) throws {
        let statement = try database.prepare(
            """
            INSERT INTO folder_members (folder_id, app_bundle_identifier, sort_order)
            VALUES (?, ?, ?);
            """
        )

        for (index, bundleIdentifier) in appBundleIdentifiers.enumerated() {
            try statement.bind(folderID.uuidString, at: 1)
            try statement.bind(bundleIdentifier, at: 2)
            try statement.bind(index, at: 3)
            _ = try statement.step()
            try statement.reset()
        }
    }

    private func dedupe(_ identifiers: [String]) -> [String] {
        var seen = Set<String>()
        return identifiers.filter { seen.insert($0).inserted }
    }
}
