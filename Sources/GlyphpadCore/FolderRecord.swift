import Foundation

public struct FolderRecord: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var appBundleIdentifiers: [String]
    public var pageIndex: Int
    public var positionIndex: Int
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        appBundleIdentifiers: [String],
        pageIndex: Int = 0,
        positionIndex: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.appBundleIdentifiers = appBundleIdentifiers
        self.pageIndex = pageIndex
        self.positionIndex = positionIndex
        self.updatedAt = updatedAt
    }
}
