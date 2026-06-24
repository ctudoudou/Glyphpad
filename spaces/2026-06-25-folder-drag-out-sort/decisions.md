# Decisions

## Source-Aware Drag State

Folder-originated drags carry the source folder ID. This keeps the UI drag code simple and lets the library decide whether it must remove an app from a folder before sorting.

## Existing Layout Persistence

Top-level ordering continues to use `SQLiteLayoutRepository.replaceAll`. No schema change is needed because dragging out creates a normal top-level app item again.

## Drop Target

Dragging out of a folder requires dropping on an existing top-level launcher item. The app is inserted before or after that target using the same left/right placement rule as normal sorting.
