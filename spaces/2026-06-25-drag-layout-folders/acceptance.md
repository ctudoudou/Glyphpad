# Acceptance

- Dragging a launcher item can start from an app tile.
- Dropping an item on another item's non-icon tile area reorders layout.
- Dropping an app on another app's icon area creates a folder.
- Dropping an app on an existing folder adds the app to the folder.
- Drag changes continue to persist through SQLite layout/folder repositories.
- Tapping an app still launches it.
- Tapping a folder still opens it.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification Notes

- `swift test` passed on 2026-06-25 with 12 XCTest tests.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed on 2026-06-25.
- The drag payload path now uses explicit `UTType.plainText` data instead of implicit `NSString` provider behavior.
- Tile tap behavior was preserved with `onTapGesture` after removing `Button` wrappers.
