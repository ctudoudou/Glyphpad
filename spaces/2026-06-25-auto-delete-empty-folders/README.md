# Auto Delete Empty Folders

## Background

Users can drag apps out of folders. When the last app leaves a folder, keeping an empty folder creates visual clutter and does not match the expected Launchpad behavior.

## Goals

- Automatically remove a folder when its member list becomes empty.
- Keep layout records consistent after a folder is removed.
- Cover folder deletion in storage tests.

## Non-Goals

- Add manual folder deletion UI.
- Change folder creation behavior.
- Change layout schema.

## Scope

- Folder repository API.
- SQLite folder deletion.
- Application library member update paths.
- Storage tests.
