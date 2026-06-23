import Foundation

public enum LayoutItemKind: String, Equatable, Sendable {
    case app
    case folder
}

public struct LayoutItem: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var kind: LayoutItemKind
    public var targetID: UUID
    public var pageIndex: Int
    public var positionIndex: Int
    public var folderID: UUID?

    public init(
        id: UUID = UUID(),
        kind: LayoutItemKind,
        targetID: UUID,
        pageIndex: Int,
        positionIndex: Int,
        folderID: UUID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.targetID = targetID
        self.pageIndex = pageIndex
        self.positionIndex = positionIndex
        self.folderID = folderID
    }
}
