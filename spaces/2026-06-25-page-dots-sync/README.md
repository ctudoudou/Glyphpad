# Page Dots Sync

## Background

Horizontal page swiping worked, but the page dots below the launcher stayed static because they only knew the total page count and did not receive the current page state.

## Goal

Keep the page dots synchronized with horizontal swipe and keyboard page navigation.

## Scope

- Lift current page state from `PagedLauncherGrid` into `LauncherView`.
- Bind `PagedLauncherGrid` scroll position to the shared current page.
- Bind `PageDots` to the same current page.
- Allow clicking a page dot to jump to that page.

## Out Of Scope

- Animated pill indicators.
- Dragging page dots.
- Changing horizontal page snap physics.
