# Launchpad Iteration Roadmap

## Background

The product target is a native macOS Launchpad replacement, not a static launcher demo. The native launchpad core now scans real apps, shows real icons, opens as a full-screen overlay, hides the Dock icon, supports search, and exits with Escape.

This roadmap records the next required iterations so implementation stays aligned.

## Required Iterations

1. **Xcode support**
   - The project must be openable and buildable from Xcode.
   - Current baseline is SwiftPM; Xcode can open the package. A dedicated Xcode project or workspace should be added if packaging, signing, or app lifecycle work needs it.

2. **Layout settings**
   - Allow row count, column count, icon size, and automatic arrangement to be configured.
   - Enforce bounds so icons never overflow the launcher surface.
   - Current foundation has `LauncherSettings` primitives; persistence and UI controls are still required.

3. **Startup and response speed**
   - Optimize launch time, app scanning, icon loading, search response, and window show/hide.
   - Add timing instrumentation before deeper optimization.

4. **No Dock icon**
   - The launcher must not show a Dock icon.
   - Current generated bundle uses `LSUIElement=true` and accessory activation policy.

5. **Scroll and paging mode**
   - Allow vertical scrolling mode or horizontal paging mode.
   - Vertical direction means scrolling through all icons.
   - Horizontal direction means pages.
   - Current foundation has a `NavigationMode` primitive; settings UI and persistence are still required.

6. **Dismiss behavior**
   - Escape exits the launcher.
   - Clicking blank space exits the launcher.
   - Current foundation implements both at the launcher surface level.

7. **Open and close animation**
   - Opening and closing should feel smooth and aligned with macOS 26/27 visual language.
   - Current foundation has fade/scale transitions; more polish is needed.

8. **Folders**
   - Dragging one app onto another should create a folder.
   - Folders must be nameable.
   - Folder membership and order must persist.

9. **Performance**
   - Optimize newly installed app detection.
   - Optimize launcher open and close.
   - Optimize icon drag performance.
   - Avoid rescanning and reloading icons unnecessarily.

## Immediate Next Step

Create a dedicated iteration for persistent layout settings and app library caching. That work should make rows, columns, icon size, and navigation mode configurable and persisted in SQLite.
