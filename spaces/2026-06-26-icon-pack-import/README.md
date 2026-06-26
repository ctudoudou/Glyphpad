# Icon Pack Import

## Background

Glyphpad currently renders the system icon for each discovered macOS app. Users should be able to personalize the launcher by importing an icon pack without changing the original app bundles.

## Goals

- Allow users to import a local icon pack from Settings.
- Match icon files to apps by bundle identifier, app name, or display name.
- Store imported icon mappings locally in SQLite.
- Render imported icons in the launcher and folder previews.

## Non-Goals

- Editing individual app icons one by one.
- Downloading icon packs from the network.
- Mutating `.app` bundles or system LaunchServices icon state.

## Scope

This iteration adds local icon override storage, import from folder or zip, settings UI controls, and launcher rendering support.
