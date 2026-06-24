import GlyphpadCore
import GlyphpadStorage
import XCTest

final class SQLiteLayoutRepositoryTests: XCTestCase {
    func testReplaceAllAndFetchAllLayoutRecords() throws {
        let repository = try makeStore().layoutRepository()

        try repository.replaceAll([
            LauncherLayoutRecord(kind: .app, targetIdentifier: "com.example.mail", positionIndex: 0),
            LauncherLayoutRecord(kind: .folder, targetIdentifier: UUID().uuidString, positionIndex: 1),
            LauncherLayoutRecord(kind: .app, targetIdentifier: "com.example.calendar", positionIndex: 2)
        ])

        let records = try repository.fetchAll()

        XCTAssertEqual(records.count, 3)
        XCTAssertEqual(records[0].kind, .app)
        XCTAssertEqual(records[0].targetIdentifier, "com.example.mail")
        XCTAssertEqual(records[0].positionIndex, 0)
        XCTAssertEqual(records[2].targetIdentifier, "com.example.calendar")
    }

    func testReplaceAllDeduplicatesRecords() throws {
        let repository = try makeStore().layoutRepository()

        try repository.replaceAll([
            LauncherLayoutRecord(kind: .app, targetIdentifier: "com.example.mail", positionIndex: 0),
            LauncherLayoutRecord(kind: .app, targetIdentifier: "com.example.mail", positionIndex: 1)
        ])

        let records = try repository.fetchAll()

        XCTAssertEqual(records, [
            LauncherLayoutRecord(kind: .app, targetIdentifier: "com.example.mail", positionIndex: 0)
        ])
    }

    private func makeStore() throws -> GlyphpadStore {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
        return try GlyphpadStore(path: url.path)
    }
}
