import AppKit
import SwiftUI

final class LauncherWindow: NSWindow {
    var dismissHandler: (() -> Void)?
    var shouldHandlePageNavigation: (() -> Bool)?

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        title = "Glyphpad"
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .stationary]
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, handlePageNavigation(event) {
            return
        }

        super.sendEvent(event)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            dismissHandler?()
            return
        }

        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command),
           event.charactersIgnoringModifiers == "," {
            NotificationCenter.default.post(name: .glyphpadToggleSettings, object: nil)
            return
        }

        super.keyDown(with: event)
    }

    private func handlePageNavigation(_ event: NSEvent) -> Bool {
        guard shouldHandlePageNavigation?() == true else {
            return false
        }
        guard event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty else {
            return false
        }

        let direction: PageNavigationDirection
        switch event.keyCode {
        case 123:
            direction = .previous
        case 124:
            direction = .next
        default:
            return false
        }

        NotificationCenter.default.post(
            name: .glyphpadNavigatePage,
            object: self,
            userInfo: ["direction": direction.rawValue]
        )
        return true
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command),
           event.charactersIgnoringModifiers == "," {
            NotificationCenter.default.post(name: .glyphpadToggleSettings, object: nil)
            return true
        }

        return super.performKeyEquivalent(with: event)
    }
}

final class EdgePinnedHostingView<Content: View>: NSHostingView<Content> {
    override var safeAreaInsets: NSEdgeInsets {
        NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    override var additionalSafeAreaInsets: NSEdgeInsets {
        get { NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) }
        set {}
    }
}
