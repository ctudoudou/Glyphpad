# Decisions

## Suppress Reopen After Close

Closing a folder sets a short suppression flag before clearing it asynchronously. This prevents the closing click from being reinterpreted as an open action on the folder tile underneath.

## Explicit Overlay Hit Area

The overlay uses a full-screen rectangular hit area for outside clicks, while the folder panel consumes its own taps so internal interaction does not close the folder accidentally.
