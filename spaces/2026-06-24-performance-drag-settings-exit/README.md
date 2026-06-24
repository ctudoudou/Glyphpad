# Performance, Drag, Settings, Exit Iteration

## Goal

Tighten the native Launchpad behavior after the first visible implementation:

- Improve launch/runtime performance without changing the native full-screen launcher direction.
- Make drag behavior less destructive by separating reorder from folder creation.
- Persist launcher ordering in SQLite.
- Improve settings window organization and reduce settings write churn.
- Make blank-area exit work inside launcher content areas, not only on the outer backdrop.

## Scope

- Add a SQLite-backed layout repository using `layout_items`.
- Maintain an ordered `launcherItems` list in `ApplicationLibrary`.
- Persist drag reorder state.
- Create folders only when an app is dropped onto another app's icon area.
- Allow dropping an app onto an existing folder to add it to the folder.
- Avoid publishing unchanged app lists and avoid full app-cache upserts when scanned metadata has not changed.
- Debounce settings persistence while sliders and controls are being adjusted.
- Split settings into Layout, Appearance, and API sections.
- Add blank-area dismissal layers inside vertical scroll and horizontal page content.

## Out Of Scope

- Spring-loaded folders while dragging.
- Animated drag previews beyond SwiftUI defaults.
- Deleting folders or removing apps from folders.
- Multi-display launcher placement policy.
- LLM classification execution.
