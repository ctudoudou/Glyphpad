# Decisions

## Persist Layout Separately

The app list is discovered from the system, but user ordering is user state. This iteration uses `layout_items` as a separate ordering layer so rescans do not erase manual organization.

## Drag Drop Semantics

Dropping onto another item's general tile area reorders. Dropping an app directly onto another app's icon area creates a folder. Dropping an app onto a folder adds it to that folder. This keeps common reorder gestures from accidentally creating folders.

## Avoid Unnecessary Work

Scanning may still happen on launch to keep the app list fresh, but unchanged scan results no longer republish the entire SwiftUI item list, and app metadata persistence only upserts changed records.

## Settings Persistence

Settings remain live while controls move, but writes are debounced. This avoids writing SQLite for every slider tick while preserving the latest configured value.

## Blank Exit

The launcher keeps the full-screen backdrop dismissal, and this iteration adds clear hit-test layers behind the grid/page content so blank clicks inside the app area also dismiss.
