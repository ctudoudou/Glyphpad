# Decisions

## Avoid High-Level Settings Windows

Settings should behave like a normal macOS configuration window, not like another full-screen overlay. The launcher window is removed before Settings opens, so Settings no longer needs to sit above a screen-saver-level window.

## Use a Sheet for Image Picking

The background image picker now uses `beginSheetModal(for:)` when a visible Settings window exists. This gives AppKit a clear modal parent and avoids fighting window levels.

## Remove Custom Panel Levels

The previous `screenSaver + n` panel levels were removed because they can interfere with system panels and make window ordering brittle.
