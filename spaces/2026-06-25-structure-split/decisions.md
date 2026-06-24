# Decisions

## Behavior-Preserving Split

This iteration is a structural refactor only. Code is moved by responsibility with minimal access-level changes required for cross-file references.

## Folder Boundaries

- `App/`: lifecycle, menu, window, global hot key, notifications, animation constants, and performance logging.
- `Settings/`: settings repository controller and settings window UI.
- `Launcher/`: full-screen launcher surface, paging grid, tiles, backdrop, and drag state.
- `Library/`: app scanning, icon cache, application library state, launcher items, and installed app model.
- `Data/`: app-level SQLite store factory.

## Access Level

Former file-private top-level types are target-internal after the split. Type internals remain private where they were already private.
