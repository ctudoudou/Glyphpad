# Keyboard Page Navigation

## Background

Horizontal page mode supported trackpad/mouse scrolling but did not respond to keyboard left and right arrows.

## Goal

Allow the launcher to move one page left or right with the keyboard arrow keys when horizontal page mode is active.

## Scope

- Intercept unmodified Left and Right arrow keys at the launcher window level.
- Only handle the keys when Settings currently uses horizontal page navigation.
- Publish page navigation events to the paged grid.
- Clamp page movement at the first and last page.

## Out Of Scope

- Keyboard focus navigation between individual app icons.
- Home/End page navigation.
- Vertical scroll mode arrow behavior changes.
