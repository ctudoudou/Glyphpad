# Folders Drag and Rename

## Background

The launcher now displays real applications, supports layout settings, hides the Dock icon, exits with Escape/blank area, and caches app metadata. The next missing core Launchpad behavior is folders.

## Goal

- Drag one app tile onto another app tile to create a folder.
- Persist folder records and folder membership.
- Show folder tiles in the launcher grid.
- Open a folder overlay to show member apps.
- Allow folder names to be edited.

## Non-Goals

- Do not implement full arbitrary icon reordering yet.
- Do not implement advanced drag performance tuning in this iteration.
- Do not implement nested folders.
- Do not implement folder deletion or app removal from folders yet.

## Scope

This is the first functional folder implementation. It should prove the Launchpad behavior exists and persists, even if later iterations improve drag polish and reordering.
