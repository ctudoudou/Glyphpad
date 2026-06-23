import Foundation

public struct AppRecord: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var bundleIdentifier: String
    public var displayName: String
    public var executablePath: String?
    public var categoryID: UUID?
    public var discoveredAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        bundleIdentifier: String,
        displayName: String,
        executablePath: String? = nil,
        categoryID: UUID? = nil,
        discoveredAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.executablePath = executablePath
        self.categoryID = categoryID
        self.discoveredAt = discoveredAt
        self.updatedAt = updatedAt
    }
}
