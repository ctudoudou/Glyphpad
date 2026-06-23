import Foundation

public enum SQLiteError: Error, Equatable, CustomStringConvertible {
    case openFailed(String)
    case prepareFailed(String)
    case stepFailed(String)
    case bindFailed(String)
    case invalidColumn(String)

    public var description: String {
        switch self {
        case .openFailed(let message):
            "SQLite open failed: \(message)"
        case .prepareFailed(let message):
            "SQLite prepare failed: \(message)"
        case .stepFailed(let message):
            "SQLite step failed: \(message)"
        case .bindFailed(let message):
            "SQLite bind failed: \(message)"
        case .invalidColumn(let message):
            "SQLite invalid column: \(message)"
        }
    }
}
