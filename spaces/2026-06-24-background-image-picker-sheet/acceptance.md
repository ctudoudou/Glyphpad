# Acceptance

- Opening Settings removes the full-screen launcher overlay first.
- Settings appears as a normal floating macOS window.
- Clicking Choose Image presents an `NSOpenPanel` attached to Settings when Settings is visible.
- The image picker no longer depends on custom screen-saver-level panel ordering.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification Notes

- `swift test` passed on 2026-06-24 with 12 XCTest tests.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed on 2026-06-24.
- Code path now uses AppKit sheet presentation instead of a high-level blocking modal panel.
