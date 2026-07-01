# Decisions

## Folder-Aware Search

When a query matches an app inside a folder, Glyphpad returns the containing folder instead of flattening the app into the top-level grid. This preserves current layout and drag semantics while making the app discoverable.

## Keyboard Scope

This iteration adds conservative keyboard behavior only: Return activates the first visible result, and Escape closes a folder before dismissing the launcher.
