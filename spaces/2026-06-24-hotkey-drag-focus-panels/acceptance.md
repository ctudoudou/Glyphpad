# Acceptance

- Horizontal page mode still snaps to complete pages and no longer feels like a purely linear strip.
- The background image picker appears above Glyphpad's launcher/settings windows and can be selected.
- Glyphpad can be shown or hidden with the default `Option + Space` global shortcut while the app is resident.
- Settings shows the active shortcut under Layout > Keyboard.
- Dropping an app tile onto another app tile creates a folder through the existing folder repository path.
- Dropping an app tile onto an existing folder adds it to that folder.
- The launcher search field is focused by default on open.
- `swift test` passes.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passes.

## Verification Notes

- `swift test` passed on 2026-06-24.
- `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed on 2026-06-24.
- Runtime launch was checked from `.build/debug/GlyphpadApp`.
- Visual screenshot captured at `dist/glyphpad-hotkey-drag-focus-check.png`.
- No failure log was emitted for registering the global hotkey during runtime launch.
- OS-level hotkey and manual drag gestures were not automated in this pass.
