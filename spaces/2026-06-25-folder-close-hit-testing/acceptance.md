# Acceptance

- Clicking outside an open folder closes it.
- The folder does not immediately reopen from the same click.
- Clicking inside the folder panel does not close it accidentally.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification

- 2026-06-25: `swift test` passed.
- 2026-06-25: `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed.
