# Decisions

## Launcher Ownership

Folder overlay components belong under `Sources/GlyphpadApp/Launcher` because they are part of the launcher surface, not settings.

## Stable Surface

The open folder uses fixed maximum dimensions derived from tile metrics so app labels and drag states do not resize the container unpredictably.

## Scroll for Large Folders

Folder contents scroll inside the folder panel once there are more apps than fit comfortably on screen.
