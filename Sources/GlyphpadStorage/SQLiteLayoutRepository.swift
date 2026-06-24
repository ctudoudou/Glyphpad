import Foundation
import GlyphpadCore

public final class SQLiteLayoutRepository: @unchecked Sendable {
    private let database: SQLiteDatabase

    init(database: SQLiteDatabase) {
        self.database = database
    }

    public func fetchAll() throws -> [LauncherLayoutRecord] {
        let statement = try database.prepare(
            """
            SELECT kind, target_id, position_index
            FROM layout_items
            WHERE folder_id IS NULL
            ORDER BY page_index ASC, position_index ASC;
            """
        )

        var records: [LauncherLayoutRecord] = []
        while try statement.step() {
            guard let kind = LauncherLayoutKind(rawValue: try statement.string(at: 0)) else {
                throw SQLiteError.invalidColumn("Invalid layout item kind")
            }

            records.append(
                LauncherLayoutRecord(
                    kind: kind,
                    targetIdentifier: try statement.string(at: 1),
                    positionIndex: statement.int(at: 2)
                )
            )
        }

        return records
    }

    public func replaceAll(_ records: [LauncherLayoutRecord]) throws {
        try database.execute("BEGIN TRANSACTION;")
        do {
            try database.execute("DELETE FROM layout_items WHERE folder_id IS NULL;")
            let statement = try database.prepare(
                """
                INSERT INTO layout_items (id, kind, target_id, page_index, position_index, folder_id)
                VALUES (?, ?, ?, 0, ?, NULL);
                """
            )

            for (index, record) in dedupe(records).enumerated() {
                try statement.bind(UUID().uuidString, at: 1)
                try statement.bind(record.kind.rawValue, at: 2)
                try statement.bind(record.targetIdentifier, at: 3)
                try statement.bind(index, at: 4)
                _ = try statement.step()
                try statement.reset()
            }

            try database.execute("COMMIT;")
        } catch {
            try? database.execute("ROLLBACK;")
            throw error
        }
    }

    private func dedupe(_ records: [LauncherLayoutRecord]) -> [LauncherLayoutRecord] {
        var seen = Set<String>()
        return records.filter { record in
            seen.insert("\(record.kind.rawValue):\(record.targetIdentifier)").inserted
        }
    }
}
