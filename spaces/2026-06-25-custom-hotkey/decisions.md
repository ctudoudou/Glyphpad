# Decisions

## Storage Shape

Store the hotkey as a key code plus Carbon modifier flags. This matches `RegisterEventHotKey` directly and avoids translating through display strings during registration.

## Default

Keep `Option + Space` as the default shortcut. Existing databases get the default through SQLite migration defaults.

## Recording Rules

Recording requires at least one modifier key. This avoids turning normal single-key typing into a global launcher shortcut. Escape cancels recording.

## Immediate Apply

The app delegate observes settings changes and re-registers the global hotkey immediately after the user records a new shortcut.

## Registration Failure

The hotkey manager registers the new shortcut before unregistering the previous one. If Carbon rejects the new shortcut because it is unavailable, the old shortcut remains active.
