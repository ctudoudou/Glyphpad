# Folder Drag Out and Persistent Sorting

## Background

Glyphpad can create folders by dragging apps together, and the main launcher grid has internal drag state. Apps inside folders currently cannot be dragged back out because folder members are not part of the top-level launcher item list.

## Goals

- Allow apps inside an open folder to be dragged back onto the launcher grid.
- Remove dragged apps from their source folder before inserting them into the top-level layout.
- Keep app and folder ordering persisted through the existing SQLite layout repository.
- Preserve the current Launchpad-like drag interaction model.

## Non-Goals

- Add nested folders.
- Add multi-select drag.
- Redesign the folder overlay.
- Change the SQLite schema.

## Scope

- Folder overlay app drag gestures.
- Drag state source tracking.
- Application library layout mutation for folder-to-grid moves.
- Sorting persistence through existing layout records.
