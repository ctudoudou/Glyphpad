# Acceptance

- Settings shows the current launcher show/hide shortcut.
- Clicking Change records the next modifier-based key combination.
- Escape cancels recording.
- Reset restores `Option + Space`.
- The selected shortcut is stored in SQLite and restored on next launch.
- Changing the shortcut re-registers the global hotkey without restarting.
- Existing databases default to `Option + Space`.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification Notes

- `swift test` passed on 2026-06-25 with 12 XCTest tests.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed on 2026-06-25.
- The settings repository test now verifies custom hotkey persistence and invalid hotkey fallback.
- OS-level shortcut collision behavior is guarded in code by keeping the previous hotkey active when Carbon rejects a new registration.
