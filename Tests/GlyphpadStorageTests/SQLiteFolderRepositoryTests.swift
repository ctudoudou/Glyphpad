import Foundation
import GlyphpadStorage
import XCTest

final class SQLiteFolderRepositoryTests: XCTestCase {
    func testCreateAndFetchFolderWithMembers() throws {
        let repository = try makeStore().folderRepository()

        let folder = try repository.create(
            name: "Work",
            appBundleIdentifiers: ["com.example.mail", "com.example.calendar"],
            positionIndex: 4
        )

        let folders = try repository.fetchAll()
        XCTAssertEqual(folders.count, 1)
        XCTAssertEqual(folders[0].id, folder.id)
        XCTAssertEqual(folders[0].name, "Work")
        XCTAssertEqual(folders[0].appBundleIdentifiers, ["com.example.mail", "com.example.calendar"])
        XCTAssertEqual(folders[0].positionIndex, 4)
    }

    func testCreateDeduplicatesMembers() throws {
        let repository = try makeStore().folderRepository()

        _ = try repository.create(
            name: "Tools",
            appBundleIdentifiers: ["com.example.terminal", "com.example.terminal", "com.example.editor"],
            positionIndex: 0
        )

        XCTAssertEqual(try repository.fetchAll()[0].appBundleIdentifiers, ["com.example.terminal", "com.example.editor"])
    }

    func testRenameFolderPersists() throws {
        let repository = try makeStore().folderRepository()
        let folder = try repository.create(
            name: "Untitled",
            appBundleIdentifiers: ["com.example.one", "com.example.two"],
            positionIndex: 0
        )

        try repository.rename(folderID: folder.id, name: "Design")

        XCTAssertEqual(try repository.fetchAll()[0].name, "Design")
    }

    private func makeStore() throws -> GlyphpadStore {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
            .path

        return try GlyphpadStore(path: path)
    }
}
