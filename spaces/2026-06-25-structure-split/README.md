# Structure Split

## Background

`Sources/GlyphpadApp/GlyphpadApp.swift` had grown into a mixed application, settings, launcher, library, and scanner file. That made behavior changes harder to review and increased the chance of accidental coupling.

## Goals

- Split the app target into responsibility-based files and folders.
- Keep the public behavior unchanged.
- Preserve the existing SwiftUI and AppKit implementation choices.
- Make future launcher, settings, and library work easier to review.

## Non-Goals

- Redesign UI.
- Change persistence schema.
- Change drag, paging, shortcut, or settings behavior.
- Add new product features.

## Scope

- App lifecycle, hot key, window, and notifications.
- Settings controller and settings UI.
- Launcher surface and launcher grid components.
- Application library, scanner, installed app model, and launcher item model.
