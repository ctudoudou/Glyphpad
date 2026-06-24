# Glyphpad

[中文说明](README.zh-CN.md)

Glyphpad is a native macOS Launchpad replacement for the post-classic-Launchpad era. It keeps the familiar full-screen app grid, search-first interaction, folders, pages, and drag organization model, while adding a separate settings window for layout, appearance, hot keys, and future LLM-assisted app classification.

The project is local-first: discovered apps, launcher layout, folders, settings, and classification data are stored in SQLite under the user's Application Support directory.

## Screenshot

![Glyphpad launcher](docs/screenshots/launcher.png)

## Features

- Full-screen Launchpad-style app grid with blurred desktop-style backdrop.
- Search field focused on launch for immediate keyboard filtering.
- Native app discovery from standard macOS application directories.
- Manual app organization with persistent drag sorting.
- Folders with editable names, app grouping, drag-in, drag-out, and automatic empty-folder cleanup.
- Vertical scrolling mode and horizontal page mode with snap paging.
- Page dots for horizontal navigation.
- Customizable grid density, rows, columns, icon size, and auto-arrange behavior.
- Custom background image and blur radius.
- Separate settings window for launcher layout, appearance, hot key, and API configuration.
- Custom global hot key for showing or hiding Glyphpad.
- SQLite-backed local persistence for apps, folders, layout, and settings.
- OpenAI-compatible API settings are present as the configuration surface for future automatic classification workflows.

## Requirements

- macOS with Xcode installed.
- Swift 6 toolchain.
- System SQLite library.

The package currently declares `.macOS(.v15)` as its build platform baseline, while the product goal is a macOS 26+ Launchpad replacement.

## Build

Build and test with Swift Package Manager:

```sh
swift build
swift test
```

Build the app scheme with Xcode:

```sh
xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build
```
Create a local app bundle:

```sh
bash scripts/build-app-bundle.sh
```

The generated bundle is written to:

```text
dist/Glyphpad.app
```

## Run

Open the generated app bundle:

```sh
open dist/Glyphpad.app
```

Glyphpad runs as an accessory-style app and does not keep a Dock icon visible while the launcher is open.

## Usage

1. Launch Glyphpad. The full-screen app grid opens immediately.
2. Type in the search field to filter apps and folders.
3. Click an app icon to launch it.
4. Click empty launcher space or press `Escape` to close the launcher.
5. Drag apps to reorder them.
6. Drag one app onto another app to create a folder.
7. Drag apps onto an existing folder to add them.
8. Open a folder, edit its title, or drag apps out to return them to the top-level grid.
9. Open Settings with `Command + ,` to adjust layout, navigation, appearance, API settings, and the global hot key.

## Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| `Option + Space` | Default global hot key to show or hide Glyphpad. This can be changed in Settings. |
| `Command + ,` | Open the Glyphpad Settings window while Glyphpad is active. |
| `Escape` | Close the launcher. |
| `Left Arrow` | Go to the previous page in horizontal page mode. |
| `Right Arrow` | Go to the next page in horizontal page mode. |
| `Command + Q` | Quit Glyphpad. |

## Settings

Glyphpad keeps launcher configuration out of the full-screen launcher surface. Settings are available in a separate window:

- **Layout**: auto-arrange, columns, rows, icon size, vertical scrolling, and horizontal pages.
- **Keyboard**: record a custom global hot key and reset it to the default.
- **Appearance**: choose a background image, clear it, and tune blur strength.
- **API**: store an OpenAI-compatible endpoint and API key locally for future classification features.

## Local Data

Runtime data is stored locally in:

```text
~/Library/Application Support/Glyphpad/Glyphpad.sqlite
```

The SQLite store includes app metadata, folders, folder members, launcher item order, launcher settings, categories, and classification suggestion tables.

## Development Workflow

Project workflow is documented in [AGENTS.md](AGENTS.md). Meaningful iterations are tracked in `spaces/YYYY-MM-DD-short-requirement-name/` with scope, TODOs, decisions, and acceptance criteria.

Relevant commands:

```sh
swift build
swift test
xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build
```
