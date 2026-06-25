# Drag Folder Effects

## Background

Dragging apps currently works, but the launcher does not clearly show whether a drop will reorder apps or create a folder. Users need stronger visual feedback while dragging.

## Goals

- Make app-to-app folder creation feel intentional with a visible merge target effect.
- Make the dragged app preview respond when it is over a merge target.
- Add lighter feedback for normal reorder targets.
- Keep the behavior native SwiftUI and avoid changing persistence or folder rules.

## Non-Goals

- Do not change the drag/drop data model.
- Do not redesign folder UI.
- Do not add new settings for animation tuning.

## Scope

Launcher grid drag visuals only.

