# Drag Layout and Folders

## Background

Dragging launcher items was not reliable: app tiles could not be used to adjust layout order, and dropping apps did not reliably create folders. The implementation used tile-level drag/drop around `Button` views and treated app-to-app drops too broadly as folder creation.

## Goal

Make dragging apps and folders usable for Launchpad-style layout organization:

- Drag to reorder launcher items.
- Drag an app onto another app's icon area to create a folder.
- Drag an app onto an existing folder to add it to that folder.

## Scope

- Replace button-based tiles with tappable views so drag gestures can start reliably.
- Use explicit `NSItemProvider` plain-text payloads for launcher item IDs.
- Distinguish folder creation from reorder by drop location.
- Preserve the existing SQLite layout and folder repository paths.

## Out Of Scope

- Spring-loaded folder opening during drag.
- Dragging apps out of folders.
- Multi-select dragging.
- Edge-triggered page switching while dragging.
