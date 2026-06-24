# Acceptance

- Apps in an open folder can be dragged onto the launcher grid.
- A dragged-out app is removed from the source folder.
- The dragged-out app appears before or after the drop target based on pointer placement.
- Top-level app sorting still works.
- Reordered top-level layout is persisted with SQLite layout records.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification

- 2026-06-25: `swift test` passed.
- 2026-06-25: `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed.
