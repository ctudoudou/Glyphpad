# Acceptance Criteria

This iteration is complete when:

- Folder records persist in SQLite.
- Folder membership persists in SQLite.
- Tests cover folder creation, membership fetch, and rename.
- Dragging one app onto another creates a folder.
- The launcher shows folder tiles.
- Opening a folder shows member apps.
- Renaming a folder persists the new name.
- `swift build`, `swift test`, and `xcodebuild` pass.
- The generated app still opens successfully.

Verification results:

- `swift build` passed on 2026-06-24.
- `swift test` passed on 2026-06-24 with 9 tests, including folder repository coverage.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed with `BUILD SUCCEEDED`.
- `bash scripts/build-app-bundle.sh` generated `/Users/potato/Projects/Glyphpad/dist/Glyphpad.app`.
- Screenshot `/tmp/glyphpad-folder-tile-fixed.png` confirmed persisted folder tile rendering.
- Screenshot `/tmp/glyphpad-folder-overlay.png` confirmed folder overlay rendering with member apps and rename field.
- Temporary local verification folder data was removed from the app database after verification.
