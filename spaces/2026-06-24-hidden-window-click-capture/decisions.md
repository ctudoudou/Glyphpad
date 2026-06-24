# Decisions

## Remove Transparent Windows

Launcher dismissal must not rely on opacity alone. A transparent full-screen window at a high level can still participate in hit testing, so the close path now orders the window out and closes it after the fade-out animation.

## Ignore Mouse Events During Dismissal

The launcher window sets `ignoresMouseEvents = true` before the animation starts. This prevents the fade-out interval from continuing to block clicks to apps behind Glyphpad.

## Keep Resident Mode

The app still hides instead of terminating after the launcher closes. This preserves the global hotkey behavior while ensuring no hidden launcher window remains interactive.
