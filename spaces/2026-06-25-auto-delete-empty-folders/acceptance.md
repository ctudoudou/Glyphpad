# Acceptance

- Dragging the last app out of a folder removes that folder.
- Moving the last app from one folder into another removes the source folder.
- Layout records are rewritten without the removed folder.
- SQLite folder deletion is covered by tests.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification

- 2026-06-25: `swift test` passed.
- 2026-06-25: `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed.
