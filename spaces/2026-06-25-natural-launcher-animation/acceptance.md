# Acceptance

- Launcher opening no longer uses a bouncy content animation.
- Launcher opening uses separate backdrop and content fade timing.
- Launcher content transition uses only subtle blur and scale.
- Launcher dismissal fades content and backdrop out without a hard cut.
- The close path still disables mouse capture before animation and closes the window after fade-out.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification Notes

- `swift test` passed on 2026-06-25 with 12 XCTest tests.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed on 2026-06-25.
- The implementation removes `.smooth(... extraBounce:)` from launcher presentation and uses explicit cubic timing curves.
