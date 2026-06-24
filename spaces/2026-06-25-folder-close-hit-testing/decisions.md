# Decisions

## Suppress Reopen After Close

Closing a folder sets a short suppression flag before clearing it asynchronously. This prevents the closing click from being reinterpreted as an open action on the folder tile underneath.

## Explicit Overlay Hit Area

The overlay uses a full-screen rectangular hit area for outside clicks, while the folder panel consumes its own taps so internal interaction does not close the folder accidentally.

## Disable Underlying Grid Hit Testing

The launcher content is removed from hit testing while a folder is open and during the close suppression window. This prevents the same mouse sequence from closing the overlay and reopening the folder tile underneath.
