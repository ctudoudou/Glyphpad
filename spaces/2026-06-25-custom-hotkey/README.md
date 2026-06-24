# Custom Hotkey

## Background

Glyphpad previously used a fixed `Option + Space` global shortcut. The user needs the shortcut to be configurable from Settings.

## Goal

Allow the show/hide launcher shortcut to be recorded in Settings, persisted locally in SQLite, and applied immediately without restarting Glyphpad.

## Scope

- Add a persisted hotkey model to launcher settings.
- Store key code and Carbon modifier flags in SQLite.
- Migrate existing databases with default `Option + Space` values.
- Replace the static shortcut display with a recording UI.
- Re-register the global Carbon hotkey when settings change.
- Keep `Option + Space` as the default and reset target.

## Out Of Scope

- Conflict detection against every system or app shortcut.
- Multiple hotkeys.
- Import/export of shortcut profiles.
- A separate first-run permissions flow.
