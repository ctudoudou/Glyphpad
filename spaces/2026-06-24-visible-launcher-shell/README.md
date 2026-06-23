# Visible Launcher Shell

## Background

The first implementation produced a buildable Swift package and a minimal SwiftUI placeholder, but launching it with `swift run GlyphpadApp` did not give the user a normal visible macOS app experience. It also did not show a Launchpad-like surface.

## Goal

Make Glyphpad visibly launchable and recognizable as a Launchpad replacement shell:

- Provide a generated `.app` bundle that can be opened with `open`.
- Activate the app window when launched.
- Replace the placeholder with a Launchpad-style app grid surface.
- Keep the UI shell static for now; real app discovery remains a separate iteration.

## Non-Goals

- Do not implement real macOS app scanning in this iteration.
- Do not implement launching selected apps yet.
- Do not implement drag and drop, folders, pagination, or classification controls yet.
- Do not introduce a full Xcode project yet.

## Scope

This iteration is about visibility and first-screen product direction. The shell should look and behave enough like a launcher to validate that the app opens correctly.
