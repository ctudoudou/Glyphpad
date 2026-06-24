# Hotkey, Drag, Focus, and Panel Fixes

## Goal

Address the latest launchpad usability issues:

- Horizontal paging should feel less linear and more physical.
- Background image picker must appear above the launcher/settings overlay.
- Glyphpad needs a keyboard way to show after the launcher is dismissed.
- Dragging apps onto apps should reliably create folders.
- Search should be focused when the launcher opens.

## Scope

- Keep Glyphpad resident after closing the launcher.
- Register a default global hotkey: `Option + Space`.
- Show the current shortcut in Settings > Layout > Keyboard.
- Raise the image picker panel above the launcher and settings window levels.
- Replace SwiftUI `.draggable/dropDestination` with `NSItemProvider` and `onDrop`.
- Treat app-to-app drops as folder creation.
- Add search field focus on appear.
- Add page transition depth while horizontal paging snaps.

## Out Of Scope

- User-recorded custom shortcut capture.
- Drag spring-loaded folder opening.
- Drag edge zones for fine-grained reorder versus folder creation.
- Automated UI event testing for global hotkeys.
