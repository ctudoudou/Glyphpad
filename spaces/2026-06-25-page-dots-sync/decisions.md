# Decisions

## Shared Page State

The paged grid and dots now share one `currentPageID` binding. This avoids duplicate state and makes swipe, keyboard navigation, and dots render from the same source of truth.

## Clickable Dots

Dots can set `currentPageID` directly. This is a small interaction improvement and also validates that the binding works in both directions.

## Clamping Remains in Grid

The grid still clamps current page when page count changes because it owns the actual paged content and knows when the scrollable page range changes.
