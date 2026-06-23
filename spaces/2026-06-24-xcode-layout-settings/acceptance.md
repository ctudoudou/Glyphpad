# Acceptance Criteria

This iteration is complete when:

- `xcodebuild -list` proves Xcode can open the package and see app schemes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` succeeds.
- Launcher settings persist across app launches.
- Users can adjust rows, columns, icon size, automatic arrangement, and navigation mode.
- Grid layout clamps to available bounds and does not overflow horizontally.
- `swift build` passes.
- `swift test` passes.
- The generated app bundle still opens as a Dock-hidden launcher.

Verification results:

- `xcodebuild -list` passed and showed `GlyphpadApp`, `GlyphpadCore`, and `GlyphpadStorage` schemes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed with `BUILD SUCCEEDED`.
- `swift build` passed on 2026-06-24.
- `swift test` passed on 2026-06-24 with 6 tests.
- `bash scripts/build-app-bundle.sh` generated `/Users/potato/Projects/Glyphpad/dist/Glyphpad.app`.
- `PlistBuddy` confirmed `LSUIElement=true`.
- `open dist/Glyphpad.app` launched process `86331`.
- Screenshot `/tmp/glyphpad-layout-settings.png` confirmed the full-screen launcher remains visible and includes the settings control.
- Sending Escape exited the app process.
