# Xcode and Layout Settings

## Background

The native Launchpad core now opens as a real full-screen launcher with installed apps and real icons. The next required iteration starts covering the user's numbered follow-up list:

1. The project must open and build in Xcode.
2. Rows, columns, icon size, and automatic arrangement must be configurable without overflowing the launcher bounds.
5. Navigation must support vertical scrolling or horizontal paging.

## Goal

- Verify and document Xcode build support.
- Add a persistent launcher settings model.
- Let users adjust row count, column count, icon size, automatic arrangement, and navigation mode.
- Clamp layout values so the launcher grid stays inside the visible bounds.
- Keep current Dock-hidden, ESC, blank-dismiss, and transition behavior intact.

## Non-Goals

- Do not implement folder drag/drop in this iteration.
- Do not implement app library caching or file-system monitoring yet.
- Do not implement model-based classification or the full control panel yet.
- Do not replace the SwiftPM package with a manually maintained Xcode project unless Xcode package build support fails.

## Xcode Support

`xcodebuild -list` recognizes this repository as workspace `Glyphpad` and exposes these schemes:

- `Glyphpad-Package`
- `GlyphpadApp`
- `GlyphpadCore`
- `GlyphpadStorage`

This means Xcode can open the project via `Package.swift` and build package schemes. A dedicated `.xcodeproj` may still be introduced later for signing, notarization, or release packaging.
