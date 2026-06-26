# Folder App Search

## Background

Apps moved into folders are removed from the top-level launcher layout. The search view was filtering only that top-level list, so foldered apps disappeared from search.

## Goals

- Search should find apps even after they are placed inside a folder.
- Matching foldered apps should appear as app results so they can be launched directly.
- Folder name search should continue to show matching folders.

## Non-Goals

- Do not redesign the search UI.
- Do not change SQLite schema or folder persistence.
- Do not add LLM or category search in this iteration.

## Scope

Update launcher search result construction so it can expand folders during search while preserving the normal top-level grid when search is empty.
