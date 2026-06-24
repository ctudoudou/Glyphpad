# Persist User Sort Order

## Background

Launcher item order should remain stable after the user drags apps or folders into a custom order. The current library rebuild path can write layout records while app, folder, cache, and scan state are still loading, which risks overwriting a user-saved order with partial or scan-derived order.

## Goals

- Preserve user-sorted launcher order across app restarts.
- Stop passive library rebuilds from overwriting saved layout.
- Keep explicit user organization actions saving layout immediately.

## Non-Goals

- Change SQLite schema.
- Add a visual save indicator.
- Change drag semantics.

## Scope

- Application library layout rebuild and save behavior.
- Verification with existing storage tests and app build.
