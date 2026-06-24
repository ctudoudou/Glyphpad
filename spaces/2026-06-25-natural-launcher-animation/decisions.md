# Decisions

## Separate Animation Layers

The backdrop and app grid now animate independently. This avoids the entire launcher looking like one flat layer being blurred and scaled at once.

## Timing Curves

Use explicit cubic timing curves instead of `.smooth(... extraBounce:)`. Full-screen launcher presentation should feel direct and light, not springy.

## Subtle Blur and Scale

Content now transitions from `1.018` scale and `2` points of blur to the final state. This keeps motion perceptible without the previous heavy blur.

## Window Lifecycle

The AppKit window fade remains in place because it is part of the safe close lifecycle. The close path still disables mouse events before animation and removes the window after fade-out.
