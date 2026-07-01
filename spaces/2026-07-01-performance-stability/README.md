# Performance And Stability

## Background

Glyphpad should feel immediate. App scanning, icon loading, layout updates, drag interactions, and show/hide animation all affect perceived quality.

## Goals

- Reduce unnecessary rescans and icon reloads.
- Improve observability for launch, scan, icon override, and render-related work.
- Keep drag and page transitions smooth with larger app libraries.
- Avoid blocking the main actor with file or SQLite-heavy work.

## Non-Goals

- Rewriting the UI stack.
- Changing the visual design.
- Automatic classification.

## Scope

This iteration is a stabilization pass guided by lightweight timing logs and targeted bottleneck fixes.
