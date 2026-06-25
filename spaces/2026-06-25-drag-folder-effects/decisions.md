# Decisions

## Visual State Is Derived

The drag visual state is derived from the current drag location and item frames. It does not create new model state and does not affect persistence.

## Merge Target Priority

App-to-app drops over the icon area are treated as merge candidates. They get the strongest feedback: larger target scale, glow, and a plus badge. Other valid targets get lighter reorder feedback.

## Native SwiftUI Effects

Effects use SwiftUI scale, opacity, shadow, overlay, and spring animation. No custom rendering layer or asset pipeline is introduced.

## Live Reorder Preview

Sorting previews reorder the displayed grid only. The persisted layout is still written when the drag ends. This makes the grid feel responsive without changing the existing drop contract.

## Insertion Indicator

Reorder targets show a lighter outline plus a small insertion bar on the before or after side. Merge targets keep the stronger scale, glow, and plus badge so folder creation remains visually distinct from sorting.
