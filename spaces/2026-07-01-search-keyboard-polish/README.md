# Search And Keyboard Polish

## Background

Glyphpad already supports search, folders, horizontal page navigation, and launching apps. The current search only checks top-level launcher items, so apps that live inside folders can become invisible to search.

## Goals

- Search should find apps inside folders.
- Search results should remain safe for layout persistence and drag behavior.
- Keyboard interaction should feel closer to native Launchpad.
- Empty search and page state should stay coherent as the query changes.

## Non-Goals

- Automatic classification.
- LLM-assisted search.
- Full Spotlight-style ranking.
- Flattening foldered apps into draggable top-level search results before drag semantics are redesigned.

## Scope

This iteration keeps the launcher model intact: foldered app matches surface their containing folder first, and keyboard commands operate on the visible result set.
