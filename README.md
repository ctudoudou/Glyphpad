# Glyphpad

Glyphpad is a native macOS 26+ Launchpad replacement. It aims to preserve the classic Launchpad grid, folders, search, and organization model while adding a separate control panel for automatic app classification and LLM-assisted category suggestions.

The project is currently in foundation implementation. See [AGENTS.md](AGENTS.md) and `spaces/` for the active workflow and iteration records.

## Development

```sh
swift build
swift test
```

Xcode can open this repository directly from `Package.swift`. The current package exposes the `GlyphpadApp`, `GlyphpadCore`, and `GlyphpadStorage` schemes.

Build the app scheme from the command line with Xcode:

```sh
xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build
```

## Launch Locally

Build a local macOS app bundle:

```sh
bash scripts/build-app-bundle.sh
```

Open the generated app:

```sh
open dist/Glyphpad.app
```

The generated app bundle runs as an accessory-style launcher and sets `LSUIElement=true`, so Glyphpad does not show a Dock icon while the launcher is open.
