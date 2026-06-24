# Decisions

## Window-Level Capture

Handle Left and Right in `LauncherWindow.sendEvent` instead of relying on a focused SwiftUI view. The launcher keeps the search field focused by default, so a lower-level view handler could miss arrow key events.

## Horizontal Mode Only

The window checks the current navigation mode before intercepting arrow keys. Vertical scroll mode keeps its existing behavior.

## Page Boundaries

The paged grid clamps keyboard movement to the available page range. Pressing Left on the first page or Right on the last page is a no-op.
