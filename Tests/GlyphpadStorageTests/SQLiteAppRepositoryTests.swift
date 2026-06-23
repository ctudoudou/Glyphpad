import Foundation
import GlyphpadCore
import GlyphpadStorage
import XCTest

final class SQLiteAppRepositoryTests: XCTestCase {
    func testUpsertAndFetchAppRecord() throws {
        let store = try makeStore()
        let repository = store.appRepository()
        let app = AppRecord(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            bundleIdentifier: "com.example.editor",
            displayName: "Example Editor",
            executablePath: "/Applications/Example Editor.app",
            discoveredAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )

        try repository.upsert(app)

        let fetched = try XCTUnwrap(repository.fetch(bundleIdentifier: "com.example.editor"))
        XCTAssertEqual(fetched, app)
    }

    func testUpsertUpdatesExistingBundleIdentifier() throws {
        let store = try makeStore()
        let repository = store.appRepository()
        let original = AppRecord(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            bundleIdentifier: "com.example.notes",
            displayName: "Example Notes",
            executablePath: "/Applications/Example Notes.app",
            discoveredAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let updated = AppRecord(
            id: original.id,
            bundleIdentifier: original.bundleIdentifier,
            displayName: "Example Notes Pro",
            executablePath: "/Applications/Example Notes Pro.app",
            discoveredAt: original.discoveredAt,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_500)
        )

        try repository.upsert(original)
        try repository.upsert(updated)

        let apps = try repository.fetchAll()
        XCTAssertEqual(apps, [updated])
    }

    func testFetchAllSortsByDisplayName() throws {
        let store = try makeStore()
        let repository = store.appRepository()

        try repository.upsert(AppRecord(bundleIdentifier: "com.example.zebra", displayName: "Zebra"))
        try repository.upsert(AppRecord(bundleIdentifier: "com.example.alpha", displayName: "Alpha"))

        let names = try repository.fetchAll().map(\.displayName)
        XCTAssertEqual(names, ["Alpha", "Zebra"])
    }

    private func makeStore() throws -> GlyphpadStore {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
            .path

        return try GlyphpadStore(path: path)
    }
}
