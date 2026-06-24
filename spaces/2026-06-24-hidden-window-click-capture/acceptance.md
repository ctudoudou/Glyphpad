# Acceptance

- Dismissing the launcher makes the full-screen launcher window stop receiving mouse events immediately.
- After the fade-out animation, the launcher window is ordered out and closed.
- Glyphpad can remain resident for `Option + Space` without leaving an invisible click-capturing window.
- Duplicate close requests during the animation do not stack multiple close flows.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification Notes

- `swift test` passed on 2026-06-24 with 12 XCTest tests.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed on 2026-06-24.
- The fix is code-verified at the AppKit window lifecycle level: dismissal now disables hit testing before fade-out and calls `orderOut` plus `close` after fade-out.
