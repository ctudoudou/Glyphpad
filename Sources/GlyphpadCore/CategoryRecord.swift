import Foundation

public struct CategoryRecord: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var sortOrder: Int
    public var isSystemSuggested: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int,
        isSystemSuggested: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.isSystemSuggested = isSystemSuggested
    }
}
