# Acceptance Criteria

This iteration is complete when:

- `GlyphpadApp` shows a Launchpad-style grid instead of placeholder text.
- A script can generate `dist/Glyphpad.app`.
- `open dist/Glyphpad.app` starts a running app process.
- The generated app is not committed as source.
- `swift build` passes.
- `swift test` passes.

Manual verification:

- Confirm the app process is visible after opening the generated bundle.
- Confirm this iteration does not pretend to support real app scanning or app launching yet.

Verification results:

- `swift build` passed on 2026-06-24.
- `swift test` passed on 2026-06-24 with 3 SQLite persistence tests.
- `bash scripts/build-app-bundle.sh` generated `/Users/potato/Projects/Glyphpad/dist/Glyphpad.app`.
- `open dist/Glyphpad.app` launched `/Users/potato/Projects/Glyphpad/dist/Glyphpad.app/Contents/MacOS/Glyphpad`.
- Screen capture confirmed the Launchpad-style Glyphpad window is visible.
