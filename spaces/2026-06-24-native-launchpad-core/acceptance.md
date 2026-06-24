# Acceptance Criteria

This iteration is complete when:

- The launcher uses real installed `.app` bundles.
- Real macOS app icons are displayed.
- Search filters real app records.
- Clicking an app launches it through native macOS APIs.
- The generated bundle opens as a full-screen overlay-style launcher.
- Dock does not show a Glyphpad icon while the launcher is open.
- ESC exits the launcher.
- `swift build` passes.
- `swift test` passes.
- A screenshot confirms the launcher is visible with real app icons.

Verification results:

- `swift build` passed on 2026-06-24.
- `swift test` passed on 2026-06-24 with 3 SQLite persistence tests.
- `bash scripts/build-app-bundle.sh` generated `/Users/potato/Projects/Glyphpad/dist/Glyphpad.app`.
- `PlistBuddy` confirmed `LSUIElement=true` in the generated app bundle.
- `open dist/Glyphpad.app` launched process `60890`.
- Screenshot `/tmp/glyphpad-appkit-launchpad.png` confirmed a full-screen launcher surface with real app icons.
- Sending Escape with System Events exited the app process.
