import Foundation

public enum LauncherLayoutKind: String, Equatable, Sendable {
    case app
    case folder
}

public struct LauncherLayoutRecord: Equatable, Sendable {
    public var kind: LauncherLayoutKind
    public var targetIdentifier: String
    public var positionIndex: Int

    public init(kind: LauncherLayoutKind, targetIdentifier: String, positionIndex: Int) {
        self.kind = kind
        self.targetIdentifier = targetIdentifier
        self.positionIndex = positionIndex
    }
}
