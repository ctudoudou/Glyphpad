# Acceptance Criteria

This iteration is complete when:

- App directory changes trigger a debounced app library refresh.
- Launcher open and close paths log elapsed time.
- Cache load, scan, publish, and persist paths log elapsed time.
- Folder member lookup avoids rebuilding app dictionaries per render.
- `swift build`, `swift test`, and `xcodebuild` pass.
- The generated app bundle still opens and exits successfully.
