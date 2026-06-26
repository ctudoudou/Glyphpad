import Foundation
import GlyphpadCore

public protocol AppIconOverrideRepository: Sendable {
    func fetchAll() throws -> [AppIconOverrideRecord]
    func upsert(_ override: AppIconOverrideRecord) throws
    func delete(bundleIdentifier: String) throws
    func deleteAll() throws
}
