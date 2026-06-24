# Page Snap and Settings UI Iteration

## Goal

Improve two visible interaction problems:

- Horizontal page mode should snap to whole pages instead of stopping between pages.
- Glyphpad Settings should feel like a polished native macOS control panel, not a simple stacked form.

## Scope

- Add SwiftUI paging target behavior to the horizontal launcher scroller.
- Keep vertical mode as continuous scrolling.
- Enlarge the settings window to provide room for real controls.
- Replace the segmented top selector with a sidebar.
- Add setting groups, section icons, descriptions, values, and previews.
- Keep all settings backed by the existing SQLite settings repository.

## Out Of Scope

- Spring-loaded page turning while dragging icons.
- Per-page custom wallpapers.
- API provider testing from the settings window.
- Full visual regression automation.
