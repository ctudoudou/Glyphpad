# Native Launchpad Core

## Background

The previous visible shell was only a static demo window. That does not satisfy Glyphpad's core requirement: replacing the classic macOS Launchpad with a native launcher surface.

## Goal

Implement the first real Launchpad-like core:

- Full-screen native overlay window.
- Scan installed `.app` bundles from standard macOS application locations.
- Show real app icons and display names.
- Search real installed apps.
- Launch apps through `NSWorkspace` when selected.
- Keep classification, folders, drag organization, and control panel for later iterations.

## Non-Goals

- Do not implement automatic classification in this iteration.
- Do not implement folders, paging persistence, or drag and drop yet.
- Do not implement the control panel yet.
- Do not attempt to perfectly clone private Apple animations.

## Scope

This iteration must make the app behave like a real launcher rather than a static prototype. Visual polish can continue later, but fake app data is not acceptable.
