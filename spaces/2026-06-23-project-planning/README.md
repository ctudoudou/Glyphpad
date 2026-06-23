# Project Planning

## Background

macOS 26 replaces the classic Launchpad experience with a newer Apps and Spotlight-oriented entry point. Glyphpad is planned as a native macOS 26+ Launchpad replacement that preserves the familiar grid, folder, search, and organization model while adding a separate control panel for automatic app classification.

## Goal

Define the project workflow before development starts:

- Branch management.
- Requirement management through `spaces/`.
- Iteration records and acceptance criteria.
- Commit discipline.
- Initial product and technical direction.
- SQLite as the local data storage baseline.

## Non-Goals

- Do not scaffold the macOS app in this iteration.
- Do not implement app scanning, UI, SQLite schema, or LLM calls yet.
- Do not generate branding, icons, marketing assets, or mockups yet.
- Do not decide every future feature in detail; only set enough structure to prevent drift.

## Product Direction

Glyphpad should feel like a native continuation of Launchpad, not a generic launcher. The core launcher should stay fast and visual. Advanced behavior belongs in a separate control panel:

- Manual app categories and folders.
- Automatic classification suggestions.
- LLM provider configuration.
- Privacy controls for model payloads.
- Rules for applying or reviewing suggested categories.

## Engineering Direction

The app should be native macOS:

- Swift + SwiftUI for primary UI.
- AppKit where full-screen overlay, global shortcut, or system integration requires it.
- SQLite for local persistence.
- Provider abstraction for LLM-backed classification.
- Deterministic rules before model-assisted classification.

## Next Spaces

Planned follow-up spaces:

- `2026-06-24-product-scope-mvp`
- `2026-06-25-technical-architecture`
- `2026-06-26-native-launchpad-ui-spec`
- `2026-06-27-auto-categorization-design`
