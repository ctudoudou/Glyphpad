# Acceptance

- `GlyphpadApp.swift` is reduced to the app entry point.
- App lifecycle, settings, launcher, and library code are separated by folder.
- The refactor does not intentionally change runtime behavior.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification

- 2026-06-25: `swift test` passed.
- 2026-06-25: `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed.
