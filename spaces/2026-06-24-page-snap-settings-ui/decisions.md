# Decisions

## Page Snap

Horizontal navigation is page-based. The implementation uses SwiftUI scroll target paging so the scroll view settles on complete page widths instead of arbitrary intermediate offsets.

## Settings Structure

The settings window now follows a macOS-style sidebar layout:

- Layout: rows, columns, icon size, and navigation.
- Appearance: background image and blur.
- API: future classification provider configuration.

This keeps settings scalable as automatic classification and provider controls are added.

## Visual Direction

Use native materials, restrained color, SF Symbols, compact descriptions, and small previews. The UI should feel like a utility panel for repeated use rather than a marketing surface.
