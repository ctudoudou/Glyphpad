# Acceptance

- `swift test` passed with 9 tests.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed with `BUILD SUCCEEDED`.
- `bash scripts/build-app-bundle.sh` generated `/Users/potato/Projects/Glyphpad/dist/Glyphpad.app`.
- `open -n /Users/potato/Projects/Glyphpad/dist/Glyphpad.app` launched the app.
- `screencapture -x /Users/potato/Projects/Glyphpad/dist/glyphpad-launchpad-check.png` confirmed a full-screen Launchpad-style grid is visible.
