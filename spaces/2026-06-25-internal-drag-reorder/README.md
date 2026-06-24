# Internal Drag Reorder

## Background

System drag/drop remained unreliable for launcher icon sorting. Even after removing `Button` wrappers and using explicit `NSItemProvider` payloads, the user still could not drag icons to adjust order.

## Goal

Replace system drag/drop for launcher organization with an internal drag gesture and hit-testing path.

## Scope

- Track launcher item frames in a named SwiftUI coordinate space.
- Use `DragGesture` on launcher tiles to start drag without AppKit drop negotiation.
- Show a lightweight drag preview following the pointer.
- On drag end, hit-test the target tile and call the existing layout/folder logic.
- Insert before or after a target based on the target tile half where the drag ends.
- Keep icon-hot-zone folder creation.

## Out Of Scope

- Dragging items out of folders.
- Dragging across pages with edge autoscroll.
- Multi-item drag.
- Full visual insertion indicators.
