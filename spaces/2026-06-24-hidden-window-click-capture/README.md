# Hidden Window Click Capture Fix

## Background

After dismissing the launcher, Glyphpad could disappear visually while still receiving mouse clicks. The likely cause was the full-screen borderless launcher window being faded to transparent and dereferenced without being removed from AppKit's window stack.

## Goal

Make launcher dismissal release mouse capture immediately and remove the full-screen window from the visible window system after the close animation.

## Scope

- Stop the launcher window from receiving mouse events as soon as dismissal starts.
- Prevent duplicate dismissal animations.
- Order out and close the launcher window after fade-out.
- Keep the resident-app behavior required by the global hotkey.

## Out Of Scope

- Changing the global hotkey behavior.
- Reworking settings window lifetime.
- Replacing the launcher close animation.
