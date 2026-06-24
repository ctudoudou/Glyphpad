# Decisions

## 1. Watch Standard App Roots First

Watch `/Applications`, `/System/Applications`, `/System/Applications/Utilities`, and the user's Applications folder. This covers the normal installation paths before adding broader Spotlight-based discovery.

## 2. Debounce Refreshes

Application installs can generate multiple filesystem events. Refreshes should be debounced to avoid repeated scans.

## 3. Log Timing With Lightweight Console Output

Use lightweight timing logs for this iteration. More formal signposts and Instruments workflows can be added later.

## 4. Cache Folder Member Lookup

Folder tiles should use an app index maintained by `ApplicationLibrary`, not rebuild dictionaries on every render.
