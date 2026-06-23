# Acceptance Criteria

This iteration is complete when:

- The repository has a Swift package manifest.
- The package builds with `swift build`.
- SQLite-backed schema initialization exists.
- App record persistence has a repository boundary.
- Tests prove that app records can be inserted and fetched from SQLite.
- A minimal SwiftUI app entry point exists.
- The active space records decisions, TODOs, and verification status.

Manual verification:

- Confirm no full product UI is implemented in this foundation iteration.
- Confirm persistence code is not coupled directly to SwiftUI views.

Verification results:

- `swift test` passed on 2026-06-23 with 3 XCTest cases covering SQLite app record persistence.
- `swift build` passed on 2026-06-23 after rerunning with elevated permissions for SwiftPM cache access outside the workspace sandbox.
- The minimal SwiftUI executable target built as part of `swift test`.
