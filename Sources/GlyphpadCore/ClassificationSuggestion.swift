import Foundation

public enum ClassificationSource: String, Equatable, Sendable {
    case deterministicRule
    case modelProvider
    case manualReview
}

public enum ClassificationStatus: String, Equatable, Sendable {
    case pending
    case accepted
    case rejected
}

public struct ClassificationSuggestion: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var appID: UUID
    public var categoryName: String
    public var source: ClassificationSource
    public var confidence: Double
    public var rationale: String?
    public var status: ClassificationStatus
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        appID: UUID,
        categoryName: String,
        source: ClassificationSource,
        confidence: Double,
        rationale: String? = nil,
        status: ClassificationStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.appID = appID
        self.categoryName = categoryName
        self.source = source
        self.confidence = confidence
        self.rationale = rationale
        self.status = status
        self.createdAt = createdAt
    }
}
