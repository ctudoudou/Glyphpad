# Decisions

## Layered Animation

Keep AppKit window alpha animation for the full-screen window lifecycle and add SwiftUI content animation for the visible launcher surface. This avoids regressing the previous fix that removes the window after dismissal.

## Dismissal Signal

Use a local notification to tell `LauncherView` that dismissal has started. The view can then animate its content out before the window is ordered out and closed.

## Motion Style

Use opacity, slight scale, and blur. This keeps the effect close to Launchpad's lightweight feel without introducing heavy per-icon animation or layout shifts.
