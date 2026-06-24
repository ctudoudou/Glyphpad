# Launcher Fade Animation

## Background

The launcher window already used AppKit alpha changes, but the launcher content itself did not have a clear enter and exit animation. This made open and close feel abrupt compared with native Launchpad.

## Goal

Add a visible fade-in and fade-out animation for launcher content during launch and dismissal.

## Scope

- Add a launcher presentation state in SwiftUI.
- Fade, slightly scale, and blur launcher content during enter and exit.
- Notify the SwiftUI launcher before the AppKit window is closed.
- Keep the existing AppKit window fade and close lifecycle.

## Out Of Scope

- Customizable animation duration.
- Per-icon staggered animation.
- Changing folder open and close animation.
