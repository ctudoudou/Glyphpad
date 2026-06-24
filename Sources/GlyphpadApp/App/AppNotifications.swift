import Foundation
import SwiftUI

extension Notification.Name {
    static let glyphpadToggleSettings = Notification.Name("GlyphpadToggleSettings")
    static let glyphpadNavigatePage = Notification.Name("GlyphpadNavigatePage")
    static let glyphpadLauncherWillDismiss = Notification.Name("GlyphpadLauncherWillDismiss")
}

enum PageNavigationDirection: String {
    case previous
    case next
}

enum LauncherDropPlacement {
    case before
    case after
}

enum LauncherPresentationAnimation {
    static let backdropIn = Animation.timingCurve(0.19, 1.0, 0.22, 1.0, duration: 0.22)
    static let contentIn = Animation.timingCurve(0.19, 1.0, 0.22, 1.0, duration: 0.28)
    static let backdropOut = Animation.timingCurve(0.4, 0.0, 1.0, 1.0, duration: 0.16)
    static let contentOut = Animation.timingCurve(0.4, 0.0, 1.0, 1.0, duration: 0.14)
}

enum PerformanceLog {
    static func start() -> TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    static func finish(_ name: String, startedAt start: TimeInterval, metadata: String = "") {
        let elapsedMilliseconds = (ProcessInfo.processInfo.systemUptime - start) * 1_000
        let suffix = metadata.isEmpty ? "" : " \(metadata)"
        NSLog("Glyphpad performance: \(name) %.1fms\(suffix)", elapsedMilliseconds)
    }

    @discardableResult
    static func measure<T>(_ name: String, metadata: String = "", _ work: () throws -> T) rethrows -> T {
        let startedAt = start()
        defer {
            finish(name, startedAt: startedAt, metadata: metadata)
        }
        return try work()
    }
}
