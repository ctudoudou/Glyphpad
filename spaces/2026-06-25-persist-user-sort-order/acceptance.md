# Acceptance

- Drag reorder still saves layout immediately.
- Passive app reloads do not overwrite saved order.
- Saved layout is applied when apps are loaded on the next launch.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification

- 2026-06-25: `swift test` passed.
- 2026-06-25: `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed.
