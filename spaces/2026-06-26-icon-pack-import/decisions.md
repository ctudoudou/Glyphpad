# Decisions

## Local Overrides

Imported icon packs create local overrides keyed by app bundle identifier. Glyphpad copies matched image files into its Application Support directory, so imported icons keep working after the original pack folder is moved or deleted.

## Matching Rules

Icon files are matched by normalized filename against app bundle identifier, app id, display name, and `.app` bundle name. Supported formats are `icns`, `png`, `jpg`, `jpeg`, `tif`, `tiff`, and `webp`.

## UI Location

Icon pack import belongs in Appearance settings. The launcher surface stays focused on launching apps, while customization remains in the separate control panel.

## No App Mutation

Glyphpad does not modify original applications or macOS LaunchServices icon metadata. Overrides only affect Glyphpad rendering.
