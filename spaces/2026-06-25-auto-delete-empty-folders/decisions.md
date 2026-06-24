# Decisions

## Delete at Member Update Boundary

Empty-folder cleanup is handled by application library member update helpers. Any path that removes the final member deletes the folder instead of writing an empty member list.

## No Schema Change

The existing folder member foreign key already cascades member deletion. Top-level launcher layout is refreshed through the existing layout replacement path.
