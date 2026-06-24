# Decisions

## Internal Drag Instead of System Drop

System `onDrag`/`onDrop` was not reliable enough in Glyphpad's full-screen launcher surface. The new path uses SwiftUI `DragGesture` and internal frame hit-testing, then calls the existing model operations directly.

## Persistence Boundary

The new gesture layer does not write SQLite directly. It still routes through `ApplicationLibrary.handleDrop`, which uses the existing layout and folder repositories.

## Folder Hot Zone

Dropping an app on another app's icon area creates a folder. Dropping elsewhere on the target tile reorders. This preserves Launchpad-style folder creation without making ordinary sorting too easy to misfire.

## Before and After Placement

Dropping on the left half of a target tile inserts before it. Dropping on the right half inserts after it. This fixes adjacent forward moves that previously looked like no-ops when everything was interpreted as "move before target."

## Visual Feedback

The original tile fades slightly while dragging, and a lightweight preview follows the pointer. This gives clear feedback without introducing full insertion animations yet.
