# Acceptance Criteria

This iteration is complete when:

- `ApplicationLibrary` can publish cached apps before a fresh scan completes.
- Fresh scan metadata is persisted back to SQLite.
- App icons are cached in memory by app URL.
- `swift build` passes.
- `swift test` passes.
- The generated bundle still opens the launcher successfully.

Verification results:

- `swift build` passed on 2026-06-24.
- `swift test` passed on 2026-06-24 with 6 tests.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed with `BUILD SUCCEEDED`.
- `bash scripts/build-app-bundle.sh` generated `/Users/potato/Projects/Glyphpad/dist/Glyphpad.app`.
- `open dist/Glyphpad.app` launched process `97423`.
- Screenshot `/tmp/glyphpad-performance-cache.png` confirmed the launcher still opens with real app icons.
- SQLite app cache contained 123 app records after background refresh.
- Sending Escape exited the app process.
