<div align="center">
<h1>Glyphpad</h1>
<h4 style="font-weight: bold">A Native macOS Launchpad Replacement</h4>

![Version](https://img.shields.io/badge/version-1.0.0-blue)

> [!NOTE]
> Apple made Launchpad disappear. Glyphpad wants to bring it back, the open-source way.

</div>

[中文说明](README.zh-CN.md)


This is a native macOS Launchpad replacement that is only about **3 MB**:

1. Open it;

2. Type a few letters;

3. Launch the app;

4. Then get back to what you were doing.

Glyphpad keeps the classic full-screen grid, search, folders, pages, and drag sorting, then adds the things Launchpad should have had: custom layout, custom background, a global hot key, and a separate settings window. Your important data stays local in SQLite. Future LLM-assisted organization will be a helper, not a tiny robot trying to take over your Mac.

## Screenshot

![Glyphpad launcher](docs/screenshots/launcher.png)

## Highlights

- **Launchpad is back**: after Apple removed it, Glyphpad brings the full-screen app grid back.
- **Only about 3 MB**: small enough to feel like a system utility, not another platform.
- **Native and fast**: it is a macOS app.
- **Search first**: open it and start typing. The search field is already ready.
- **Folders and sorting are saved**: drag apps around, create folders, move apps in and out, and Glyphpad remembers the layout.
- **No empty-folder graveyard**: empty folders clean themselves up.
- **Classic or compact**: use horizontal pages for the Launchpad rhythm, or vertical scrolling when you have a lot of apps.
- **Custom Launchpad background**: use your own image and tune the blur so it feels like your launcher, not a rented screen.
- **Make it yours**: tune rows, columns, icon size, background image, blur strength, and auto-arrange behavior.
- **Global hot key**: summon it with one shortcut, or change the shortcut to your own.
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

Create a local macOS app bundle:

```sh
bash scripts/build-app-bundle.sh
```

The generated bundle is written to:

```text
dist/Glyphpad.app
```

## Usage

Open the generated app:

```sh
open dist/Glyphpad.app
```

Glyphpad runs as an accessory-style app, so it does not keep a Dock icon visible while the launcher is open.

Basic flow:

1. Open Glyphpad and the full-screen launcher appears.
2. Type to search, then click an app to launch it.
3. Press `ESC` or click empty space when you are done.
4. Drag apps to reorder them.
5. Drag one app onto another to create a folder.
6. Move apps into a folder, or drag them back out to the top level.
7. Use `Command + ,` to open Settings and tune layout, pages, background, API settings, and the global hot key.
8. Use `Option + Space` for quick launch.

## Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| `Option + Space` | Default global hot key to show or hide Glyphpad. This can be changed in Settings. |
| `Command + ,` | Open the Glyphpad Settings window while Glyphpad is active. |
| `ESC` | Close the launcher. |
| `Left Arrow` | Go to the previous page in horizontal page mode. |
| `Right Arrow` | Go to the next page in horizontal page mode. |
| `Command + Q` | Quit Glyphpad. |

## Settings

Glyphpad does not stuff the launcher full of buttons. All configuration lives in a separate Settings window:

- **Layout**: auto-arrange, columns, rows, icon size, vertical scrolling, and horizontal pages.
- **Keyboard**: record a custom global hot key and reset it to the default.
- **Appearance**: choose a background image, clear it, and tune blur strength.
- **API**: store an OpenAI-compatible endpoint and API key locally for future classification features.

## Local Data

Runtime data is stored locally in:

```text
~/Library/Application Support/Glyphpad/Glyphpad.sqlite
```

The SQLite database stores app metadata, folders, folder members, launcher layout order, launcher settings, categories, and classification suggestion tables.

## Development Workflow

Project workflow is documented in [AGENTS.md](AGENTS.md). Meaningful iterations are tracked in `spaces/YYYY-MM-DD-short-requirement-name/` with background, TODOs, decisions, and acceptance criteria.

Common development commands:

```sh
swift build
swift test
xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build
```
