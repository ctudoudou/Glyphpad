# Acceptance

- Swiping horizontally updates the highlighted page dot.
- Keyboard left/right page navigation updates the highlighted page dot.
- Clicking a dot scrolls to the corresponding page.
- Page state remains clamped when page count changes.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification

- 2026-06-25: `swift test` passed.
- 2026-06-25: `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed.
