# Glyphpad

[中文说明](README.zh-CN.md)

Apple took Launchpad away. Glyphpad brings it back, the open-source way.

It is a native, fast Launchpad replacement for modern macOS: open it, type a few letters, launch the app, and get back to what you were doing. No web wrapper. No heavy control center. The current local app bundle is only about **3 MB**.

Glyphpad keeps the classic full-screen grid, search, folders, pages, and drag sorting, then adds the things Launchpad should have had: custom layout, custom background, a global hot key, and a separate settings window. Everything important stays local in SQLite. Future LLM-assisted organization is planned as a helper, not something that takes over your Mac.

## Screenshot

![Glyphpad launcher](docs/screenshots/launcher.png)

## Why Glyphpad

- **Launchpad is back**: the same full-screen app grid idea, rebuilt for macOS after Apple removed it.
- **Only about 3 MB**: small enough to feel like part of the system.
- **Native and fast**: built as a macOS app, not a web page pretending to be one.
- **Search first**: open Glyphpad and start typing. The search field is already focused.
- **Folders and sorting that stick**: drag apps around, create folders, move apps in and out, and your layout is saved.
- **No folder mess**: empty folders clean themselves up.
- **Classic or compact**: use horizontal pages for the Launchpad feel, or vertical scrolling for long app lists.
- **Make it yours**: tune rows, columns, icon size, background image, blur, and auto-arrange behavior.
- **Global hot key**: summon it instantly, and change the shortcut whenever you want.
- **Local-first by default**: app metadata, layout, folders, settings, and future classification history stay in SQLite on your Mac.
- **Ready for smarter organization**: OpenAI-compatible API settings are already in place for future automatic classification workflows.

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

1. Open Glyphpad and the launcher appears full screen.
2. Type to search, then click an app to launch it.
3. Press `Escape` or click empty space when you are done.
4. Drag apps to reorder them.
5. Drag one app onto another to make a folder.
6. Drag apps into a folder, or drag them back out when you change your mind.
7. Open Settings with `Command + ,` to tune layout, pages, background, API settings, and the global hot key.

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

Glyphpad keeps the launcher clean. All the knobs live in a separate Settings window:

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
