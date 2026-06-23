import Foundation
import GlyphpadCore

public protocol AppRepository: Sendable {
    func upsert(_ app: AppRecord) throws
    func fetchAll() throws -> [AppRecord]
    func fetch(bundleIdentifier: String) throws -> AppRecord?
}
