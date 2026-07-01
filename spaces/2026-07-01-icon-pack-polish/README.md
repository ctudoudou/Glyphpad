# Icon Pack Polish

## Background

Glyphpad can import icon packs and store icon overrides locally. The next polish pass should make the feature feel production-grade.

## Goals

- Refresh launcher icons immediately after import or clear.
- Show matched and unmatched import details.
- Clean up copied icon files when overrides are cleared.
- Keep icon pack import responsive for larger icon packs.

## Non-Goals

- Network icon pack discovery.
- Mutating original `.app` bundles.
- Cloud sync.

## Scope

This iteration will refine the existing local icon pack feature without changing its data ownership model.
