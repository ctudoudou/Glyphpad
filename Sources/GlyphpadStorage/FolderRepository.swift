import Foundation
import GlyphpadCore

public protocol FolderRepository: Sendable {
    func fetchAll() throws -> [FolderRecord]
    func create(name: String, appBundleIdentifiers: [String], positionIndex: Int) throws -> FolderRecord
    func rename(folderID: UUID, name: String) throws
}
