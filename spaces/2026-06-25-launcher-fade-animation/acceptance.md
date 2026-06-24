# Acceptance

- Opening the launcher fades the visible launcher surface in.
- Opening the launcher uses a slight scale/blur transition instead of a hard cut.
- Closing the launcher fades the visible launcher surface out.
- Closing the launcher still disables mouse capture and removes the window after the fade.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification Notes

- `swift test` passed on 2026-06-25 with 12 XCTest tests.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed on 2026-06-25.
- Dismissal still sets `ignoresMouseEvents` before animation and closes the window after fade-out.
