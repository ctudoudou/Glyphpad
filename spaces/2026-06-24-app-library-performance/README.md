# App Library Performance

## Background

The launcher currently scans installed applications and creates app icons when it opens. That is correct behaviorally, but it is not enough for the user's performance requirement:

- Optimize launcher startup.
- Optimize response speed.
- Optimize newly installed app detection.
- Avoid unnecessary rescans and icon reloads.

## Goal

- Load cached app metadata from SQLite immediately.
- Refresh installed app metadata in the background.
- Persist refreshed app metadata back to SQLite.
- Cache icons in memory while the launcher is running.
- Keep the UI responsive during scanning.

## Non-Goals

- Do not implement file-system watching yet.
- Do not implement drag performance or folder drag/drop in this iteration.
- Do not implement a full benchmarking dashboard yet.

## Scope

This iteration starts the performance foundation. It should reduce launcher startup work on repeat opens and avoid blocking the main UI on filesystem scanning.
