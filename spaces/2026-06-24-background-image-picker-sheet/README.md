# Background Image Picker Sheet Fix

## Background

Clicking the background image button in Settings still did not show a selectable image picker. The previous fix raised the open panel level, but Settings and Launcher were still using high-level overlay windows that could interfere with system modal panels.

## Goal

Make the background image picker appear reliably from Settings.

## Scope

- Remove the full-screen launcher window before opening Settings.
- Use a normal floating Settings window instead of a screen-saver-level panel.
- Present the image picker as a sheet attached to Settings when possible.
- Avoid custom high-level window constants for Settings and the image picker.

## Out Of Scope

- Redesigning Settings.
- Adding drag-and-drop image import.
- Adding recent images or wallpaper presets.
