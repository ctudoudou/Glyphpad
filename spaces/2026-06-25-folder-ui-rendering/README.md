# Folder UI Rendering

## Background

The folder overlay works functionally, but the visual layout is basic and its code still lives in the settings UI file after the structural split. Folder UI should belong to the launcher surface and should render predictably as folder contents grow.

## Goals

- Improve the open-folder overlay so it feels closer to a native Launchpad folder surface.
- Keep icon layout stable with bounded width, height, and scrolling.
- Improve folder tile preview rendering for 0-4 visible member icons.
- Move folder overlay code into the launcher area.

## Non-Goals

- Change folder persistence schema.
- Add nested folders.
- Change drag semantics.
- Add folder deletion.

## Scope

- Open-folder overlay.
- Folder member drag tile rendering.
- Folder icon preview rendering.
- File organization for folder UI components.
