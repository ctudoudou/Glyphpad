# Acceptance

- Dragging an app over another app's icon area shows a clear merge effect on the target.
- The dragged preview grows while a folder creation merge is possible.
- Normal reorder targets show lighter feedback than merge targets.
- Drag sorting previews the resulting grid order before mouse release.
- Reorder targets indicate whether the dragged app will be inserted before or after the target.
- Existing folder creation and reorder behavior remains unchanged.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification

- 2026-06-25: `swift test` passed.
- 2026-06-25: `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed.
