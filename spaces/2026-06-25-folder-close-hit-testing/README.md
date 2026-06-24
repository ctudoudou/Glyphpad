# Folder Close Hit Testing

## Background

After a folder is open, clicking outside the folder should close it. The current interaction can immediately reopen the folder because the same click can reach the underlying folder tile after the overlay disappears.

## Goals

- Closing a folder by clicking outside should leave it closed.
- Prevent the close click from opening the folder tile underneath.
- Keep clicks inside the folder panel interactive and isolated from outside-close behavior.

## Non-Goals

- Change drag behavior.
- Change folder layout or persistence.
- Add new close buttons.

## Scope

- Folder overlay hit testing.
- Folder open/close gating in launcher view.
