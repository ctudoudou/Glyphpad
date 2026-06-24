# Acceptance

- Folder overlay code is in the launcher area.
- Open folders render with a polished title, panel, and bounded grid.
- Large folders remain usable through internal scrolling.
- Folder icon preview renders predictably with up to four member icons.
- Existing folder drag-out behavior still compiles.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification

- 2026-06-25: `swift test` passed.
- 2026-06-25: `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed.
