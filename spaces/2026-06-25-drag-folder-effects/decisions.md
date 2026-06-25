# Decisions

## Visual State Is Derived

The drag visual state is derived from the current drag location and item frames. It does not create new model state and does not affect persistence.

## Merge Target Priority

App-to-app drops over the icon area are treated as merge candidates. They get the strongest feedback: larger target scale, glow, and a plus badge. Other valid targets get lighter reorder feedback.

## Native SwiftUI Effects

Effects use SwiftUI scale, opacity, shadow, overlay, and spring animation. No custom rendering layer or asset pipeline is introduced.

