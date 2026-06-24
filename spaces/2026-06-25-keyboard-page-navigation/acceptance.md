# Acceptance

- In horizontal page mode, Left moves to the previous page.
- In horizontal page mode, Right moves to the next page.
- Page navigation stops at the first and last page.
- Vertical scroll mode does not install page-key behavior.
- Search can remain focused while page keys still work.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification Notes

- `swift test` passed on 2026-06-25 with 12 XCTest tests.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed on 2026-06-25.
- The implementation ignores Command, Option, Control, and Shift combinations so shortcut chords do not accidentally page.
