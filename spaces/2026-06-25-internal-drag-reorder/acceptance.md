# Acceptance

- Dragging an app icon starts without relying on system drag/drop.
- Releasing over another tile reorders through the internal drop path.
- Releasing on the left half of a target inserts before it.
- Releasing on the right half of a target inserts after it.
- Releasing an app over another app's icon area creates a folder.
- Releasing an app over an existing folder adds it to that folder.
- Dragging shows a visible preview and dims the source tile.
- The old system drag/drop path is removed from launcher tiles.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification Notes

- `swift test` passed on 2026-06-25 with 12 XCTest tests.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed on 2026-06-25.
- The tile implementation no longer contains `onDrag`, `onDrop`, or a `DropDelegate`; sorting now uses internal `DragGesture` hit-testing.
- Mouse gesture behavior was code-verified and build-verified, but not automated with a UI drag test in this pass.
