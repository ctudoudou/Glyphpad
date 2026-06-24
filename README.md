# Glyphpad

[中文说明](README.zh-CN.md)

Glyphpad brings the classic Launchpad feeling back to modern macOS: a fast full-screen app grid, instant search, familiar folders, page navigation, and drag organization without turning the launcher into a dashboard.

It is intentionally small, native, and local-first. The current local app bundle is only about **3 MB**, and discovered apps, launcher layout, folders, settings, and classification data live in SQLite under the user's Application Support directory.

Configuration stays out of the way in a separate settings window, where Glyphpad can grow into automatic and LLM-assisted app organization without making the launcher itself feel heavy.

## Screenshot

![Glyphpad launcher](docs/screenshots/launcher.png)

## Features

- A tiny native app bundle, currently only about **3 MB**.
- Full-screen Launchpad-style app grid with a soft blurred backdrop.
- Search is focused on launch, so you can type first and think later.
- Native app discovery from standard macOS application directories.
- Manual app organization with persistent drag sorting.
- Folders that behave like folders: rename, group apps, drag in, drag out, and let empty folders disappear.
- Vertical scroll when you want a flowing list, horizontal pages when you want the classic Launchpad rhythm.
- Page dots that stay in sync with horizontal navigation.
- Tunable density: rows, columns, icon size, and auto-arrange behavior.
- Custom background image and blur strength.
- A separate settings window for layout, appearance, hot key, and API configuration.
- A custom global hot key to summon or dismiss Glyphpad quickly.
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
