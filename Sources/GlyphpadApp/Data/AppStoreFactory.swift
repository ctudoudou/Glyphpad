import Foundation
import GlyphpadStorage

enum AppStoreFactory {
    static func makeStore() throws -> GlyphpadStore {
        let fileManager = FileManager.default
        let directory = try applicationSupportDirectory(fileManager: fileManager)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent("Glyphpad.sqlite").path
        return try GlyphpadStore(path: path)
    }

    static func applicationSupportDirectory(fileManager: FileManager) throws -> URL {
        if let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            return directory.appendingPathComponent("Glyphpad", isDirectory: true)
        }

        return URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/Glyphpad", isDirectory: true)
    }
}
