# Acceptance

## Behavior

- Horizontal launcher mode uses `.scrollTargetBehavior(.paging)`.
- Horizontal pages are declared as scroll targets with `.scrollTargetLayout()`.
- Vertical launcher mode remains a vertical scroll view.
- Settings window opens at `760 x 560` with a `700 x 520` minimum size.

## UI

- Settings has a sidebar with Layout, Appearance, and API sections.
- Layout settings include auto arrange, columns, rows, icon size, navigation, and a compact grid preview.
- Appearance settings include background image controls, blur, and a background preview.
- API settings show endpoint, API key, and configuration status.

## Verification

- `swift test` passed on 2026-06-24 with 12 tests.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed on 2026-06-24.
