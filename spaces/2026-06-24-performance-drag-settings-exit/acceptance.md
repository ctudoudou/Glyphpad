# Acceptance

## Functional

- Launcher item order persists through SQLite `layout_items`.
- Dragging one item onto another tile reorders the launcher.
- Dragging an app onto another app's icon area creates a folder.
- Dragging an app onto an existing folder adds the app to that folder.
- Blank clicks inside vertical scroll and horizontal page content can dismiss the launcher.
- Settings are organized into Layout, Appearance, and API sections.
- Settings writes are debounced instead of written on every control tick.

## Performance

- Repeated scan results do not republish unchanged launcher app metadata.
- App metadata persistence only upserts changed records.
- Runtime log from 2026-06-24 debug launch showed:
  - `launcher.open 276.4ms`
  - `library.cache.load 42.9ms`
  - `library.persist.changed count=4`
  - `library.persist 19.2ms`
  - `library.reload 263.3ms`

## Verification

- `swift test` passed on 2026-06-24 with 12 tests.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed on 2026-06-24.
- Screenshot verified full-screen launcher surface after this iteration:
  - `/Users/potato/Projects/Glyphpad/dist/glyphpad-optimized-launcher-check.png`
