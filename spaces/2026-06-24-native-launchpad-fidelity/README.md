# Native Launchpad Fidelity

## Context

The launcher must present as the macOS Launchpad replacement itself, not as a settings surface or generic app window.

## Goal

Tighten the default visible experience:

- Launch directly into a full-screen Launchpad-style surface.
- Keep the first screen focused on search and app icons.
- Move configuration out of the primary launcher view.
- Use a system material backdrop instead of a generic dark app background.

## Result

The generated app bundle launches into a full-screen grid with real app icons, centered search, and no visible settings button on the primary surface. The settings panel remains available through `Command-,` for development until the separate control panel app/window is implemented.
