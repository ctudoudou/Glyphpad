import Foundation
import GlyphpadCore
import GlyphpadStorage
import XCTest

final class SQLiteLauncherSettingsRepositoryTests: XCTestCase {
    func testLoadReturnsDefaultSettingsWhenUnset() throws {
        let store = try makeStore()
        let repository = store.launcherSettingsRepository()

        XCTAssertEqual(try repository.load(), .default)
    }

    func testSaveAndLoadLauncherSettings() throws {
        let store = try makeStore()
        let repository = store.launcherSettingsRepository()
        let settings = LauncherSettings(
            columns: 9,
            rows: 6,
            iconSize: 88,
            autoArrange: false,
            navigationMode: .horizontalPages
        )

        try repository.save(settings)

        XCTAssertEqual(try repository.load(), settings)
    }

    func testSaveClampsSettings() throws {
        let store = try makeStore()
        let repository = store.launcherSettingsRepository()
        let settings = LauncherSettings(
            columns: 30,
            rows: 1,
            iconSize: 300,
            autoArrange: false,
            navigationMode: .verticalScroll
        )

        try repository.save(settings)

        XCTAssertEqual(
            try repository.load(),
            LauncherSettings(
                columns: 12,
                rows: 3,
                iconSize: 112,
                autoArrange: false,
                navigationMode: .verticalScroll
            )
        )
    }

    private func makeStore() throws -> GlyphpadStore {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
            .path

        return try GlyphpadStore(path: path)
    }
}
