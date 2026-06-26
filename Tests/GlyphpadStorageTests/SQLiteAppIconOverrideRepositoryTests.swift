import Foundation
import GlyphpadCore
import GlyphpadStorage
import XCTest

final class SQLiteAppIconOverrideRepositoryTests: XCTestCase {
    func testUpsertAndFetchOverrides() throws {
        let repository = try makeStore().appIconOverrideRepository()
        let updatedAt = Date(timeIntervalSince1970: 1_725_000_000)

        try repository.upsert(
            AppIconOverrideRecord(
                appBundleIdentifier: "com.example.editor",
                iconPath: "/tmp/editor.png",
                sourceName: "Solar Icons",
                updatedAt: updatedAt
            )
        )

        let overrides = try repository.fetchAll()
        XCTAssertEqual(overrides.count, 1)
        XCTAssertEqual(overrides[0].appBundleIdentifier, "com.example.editor")
        XCTAssertEqual(overrides[0].iconPath, "/tmp/editor.png")
        XCTAssertEqual(overrides[0].sourceName, "Solar Icons")
        XCTAssertEqual(overrides[0].updatedAt.timeIntervalSince1970, updatedAt.timeIntervalSince1970, accuracy: 0.001)
    }

    func testUpsertReplacesExistingOverride() throws {
        let repository = try makeStore().appIconOverrideRepository()

        try repository.upsert(
            AppIconOverrideRecord(
                appBundleIdentifier: "com.example.mail",
                iconPath: "/tmp/old.png",
                sourceName: "Old"
            )
        )
        try repository.upsert(
            AppIconOverrideRecord(
                appBundleIdentifier: "com.example.mail",
                iconPath: "/tmp/new.png",
                sourceName: "New"
            )
        )

        let overrides = try repository.fetchAll()
        XCTAssertEqual(overrides.count, 1)
        XCTAssertEqual(overrides[0].iconPath, "/tmp/new.png")
        XCTAssertEqual(overrides[0].sourceName, "New")
    }

    func testDeleteOverrides() throws {
        let repository = try makeStore().appIconOverrideRepository()

        try repository.upsert(
            AppIconOverrideRecord(
                appBundleIdentifier: "com.example.one",
                iconPath: "/tmp/one.png",
                sourceName: "Pack"
            )
        )
        try repository.upsert(
            AppIconOverrideRecord(
                appBundleIdentifier: "com.example.two",
                iconPath: "/tmp/two.png",
                sourceName: "Pack"
            )
        )

        try repository.delete(bundleIdentifier: "com.example.one")
        XCTAssertEqual(try repository.fetchAll().map(\.appBundleIdentifier), ["com.example.two"])

        try repository.deleteAll()
        XCTAssertTrue(try repository.fetchAll().isEmpty)
    }

    private func makeStore() throws -> GlyphpadStore {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
            .path

        return try GlyphpadStore(path: path)
    }
}
