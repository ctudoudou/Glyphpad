# Decisions

## Global Shortcut

Use `Option + Space` as the first default global shortcut. Glyphpad now remains resident after the launcher window closes, which makes a show/hide shortcut possible without requiring a full app relaunch.

Custom shortcut recording is intentionally deferred. The settings UI shows the active shortcut so the user has a concrete path today without implying that recording is already implemented.

## Launcher Dismissal

Closing the launcher hides Glyphpad instead of terminating the process. `Command + Q` remains the explicit quit path through the application menu.

## Image Picker Layering

The background image picker is raised above the existing launcher/settings panel levels and marked as full-screen auxiliary. This keeps it selectable when the launcher uses a high overlay window level.

## Drag and Folder Creation

SwiftUI `.draggable`/`.dropDestination` was replaced with `onDrag`/`onDrop` and `NSItemProvider` text payloads. Dropping an app onto another app now routes directly into folder creation. Dropping onto an existing folder continues to add the app to that folder.

## Search Focus

The search field requests focus on appear so typing immediately after opening the launcher targets search by default.

## Paging Feel

Horizontal page mode keeps strict page snapping but adds an interactive scroll transition and smooth animation to give adjacent pages depth during motion.
