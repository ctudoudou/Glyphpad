# Decisions

## Control Panel Entry

The Launchpad surface should not advertise settings as a primary UI control. For now, `Command-,` toggles the settings panel while the launcher is open. A later iteration should move this into a genuinely independent control panel.

## Backdrop

Use AppKit system material via `NSVisualEffectView` with a restrained overlay. This keeps the launcher closer to a native desktop overlay than a branded app window.
