# Decisions

## Tappable Tiles Instead of Buttons

Launcher tiles now use `onTapGesture` instead of `Button`. This avoids the native button control consuming drag gestures before SwiftUI drag/drop can start.

## Explicit Drag Payload

The drag payload is registered as `UTType.plainText` with the launcher item ID. This is more predictable than relying on implicit `NSString` provider behavior.

## Folder Creation Hot Zone

Dropping an app onto another app's icon area creates a folder. Dropping onto the label or the rest of the tile reorders instead. This keeps sorting and folder creation as separate gestures.

## Existing Persistence Paths

The change continues to call the existing `handleDrop`, `moveItem`, `createFolder`, and `add(appID:toFolderID:)` paths so layout and folder changes keep using SQLite repositories.
