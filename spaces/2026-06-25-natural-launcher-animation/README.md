# Natural Launcher Animation

## Background

The previous launcher fade animation felt unnatural because the whole surface used a single boolean animation with bounce-like timing, aggressive blur, and simultaneous window alpha changes.

## Goal

Refine launch and dismissal animation so it feels lighter and closer to native Launchpad behavior.

## Scope

- Separate backdrop and content presentation states.
- Replace smooth/bouncy animation with explicit timing curves.
- Reduce content blur and use a subtle scale transition.
- Keep AppKit window fade for lifecycle and click-capture safety.

## Out Of Scope

- Per-icon cascade animation.
- User-configurable animation duration.
- Reworking folder overlay animation.
