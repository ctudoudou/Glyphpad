# Stable Launcher Order Fix

## Problem

Icons could change order each time the launcher opened. The root cause was that app cache loading and app scanning used different sorting sources:

- SQLite app cache sorted by `display_name COLLATE NOCASE`.
- Fresh filesystem scan sorted with Swift localized comparison.

Before a user manually dragged icons, there was no persisted `layout_items` order. The launcher could therefore render cache order first and then replace it with scan order when the scan completed.

## Fix

- Seed `layout_items` the first time a non-empty launcher item order is available.
- Preserve existing `layout_items` order on later scans.
- Append newly discovered apps after the existing order instead of reordering all apps.
- Compare app metadata signatures independent of current array ordering so a scan with the same app set does not republish the UI just because its sort order differs.
