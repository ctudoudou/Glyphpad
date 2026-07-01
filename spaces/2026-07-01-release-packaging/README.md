# Release Packaging

## Background

Glyphpad has a local app bundle build script. A real release flow needs repeatable artifacts and checks.

## Goals

- Produce a release-ready app artifact from a clean command.
- Add a DMG or zip packaging path.
- Keep version information obvious in docs and release output.
- Prepare signing and notarization hooks without requiring credentials for local builds.

## Non-Goals

- Uploading releases automatically.
- Hard-coding developer signing identities.
- Changing app functionality.

## Scope

This iteration improves local packaging scripts and documentation for release preparation.
