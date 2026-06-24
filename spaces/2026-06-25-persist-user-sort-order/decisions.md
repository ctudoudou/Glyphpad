# Decisions

## Explicit Saves Only

`rebuildLauncherItems()` applies the current `layoutOrder` to UI state, but it no longer writes layout records by itself. Layout persistence remains tied to explicit user organization actions such as sorting, creating folders, moving apps into folders, moving apps out of folders, and deleting emptied folders.

## Avoid Partial Load Writes

The startup load path can rebuild items before all app metadata is available. Avoiding writes during rebuild prevents cached or partial discovery state from replacing a previously saved user order.
