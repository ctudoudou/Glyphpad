# MVP Foundation

## Background

The planning iteration established Glyphpad as a native macOS 26+ Launchpad replacement with SQLite-backed local state. This iteration starts implementation with the smallest useful foundation that future UI, scanning, classification, and control panel work can build on.

## Goal

Create a buildable Swift foundation for Glyphpad:

- Swift package structure.
- Core domain models for apps, categories, folders, layout items, and classification suggestions.
- SQLite storage layer with schema creation.
- Repository boundary for persistence.
- Minimal SwiftUI app entry point.
- Focused tests for SQLite-backed persistence.

## Non-Goals

- Do not implement full Launchpad UI.
- Do not implement drag and drop, pagination, folders, or search UI.
- Do not scan installed macOS apps yet.
- Do not call LLM providers yet.
- Do not package, sign, or notarize the app yet.

## Scope

This iteration is allowed to introduce code, but only for project foundation. Product behavior beyond persistence should remain placeholder-level until the MVP scope and architecture spaces are expanded.
