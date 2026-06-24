# Performance Watch and Drag

## Background

The launcher now supports real apps, settings, caching, and folders. The remaining performance requirement needs deeper runtime work:

- Detect newly added apps without forcing a full relaunch.
- Keep launcher open/close responsive.
- Avoid expensive repeated work during folder rendering and drag operations.

## Goal

- Add directory watchers for standard macOS app locations.
- Debounce app library refreshes after application directory changes.
- Add lightweight performance logging for launcher open, close, cached load, scan, publish, and persist phases.
- Optimize folder member lookup so folder tiles do not rebuild app dictionaries repeatedly.
- Keep drag payloads lightweight and stable.

## Non-Goals

- Do not implement full arbitrary icon reordering yet.
- Do not implement a visual performance dashboard yet.
- Do not implement Spotlight/FSEvents recursive indexing for every possible app location yet.

## Scope

This iteration finishes the first pass of the explicit performance requirement. Future performance work can add benchmarks, Instruments traces, and reorder-specific profiling.
