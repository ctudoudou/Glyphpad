# Decisions

## Search Result Shape

When search is empty, the launcher keeps using the persisted top-level layout.

When search has a query, folders are expanded for matching purposes. A folder is shown if its name matches. Apps inside folders are shown directly when their display name or bundle identifier matches, which makes the search result immediately launchable.

## Persistence

No persistence changes are needed. This is a presentation-layer search expansion over the current in-memory library.

## Drag Behavior

Foldered apps shown as direct search results are launchable results, not top-level layout items. They do not start top-level drag organization from search results, which avoids duplicating an app into another folder without removing it from the original folder.
