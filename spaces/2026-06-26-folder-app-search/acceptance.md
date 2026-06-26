# Acceptance

- A top-level app still appears when its name or bundle identifier matches the search query.
- A folder still appears when its folder name matches the search query.
- An app inside a folder appears as an app search result when its name or bundle identifier matches the query.
- Search results do not contain duplicate app or folder tiles.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.
