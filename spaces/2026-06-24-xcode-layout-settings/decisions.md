# Decisions

## 1. Xcode Opens the Swift Package

The repository is currently a Swift package. Xcode recognizes package schemes from `Package.swift`, so the immediate Xcode requirement can be satisfied without adding a hand-maintained `.xcodeproj`.

## 2. Store Settings Outside the UI

Launcher settings should not live only as SwiftUI state. This iteration adds a small persistence boundary so future control-panel work can reuse it.

## 3. Clamp Values Before Layout

Rows, columns, and icon size must be clamped before calculating grid dimensions. Automatic arrangement must choose values based on the available screen size and configured icon size.

## 4. Navigation Mode Is Explicit

Vertical mode scrolls through all icons. Horizontal mode splits icons into pages. The setting must be explicit rather than inferred from gesture direction.
