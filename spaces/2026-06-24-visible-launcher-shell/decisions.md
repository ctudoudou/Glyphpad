# Decisions

## 1. Generate an App Bundle Before Adding Xcode Project Complexity

Use SwiftPM for now and generate a lightweight `.app` bundle in `dist/`. This makes the app visible through normal macOS launch behavior without committing to a full Xcode project structure yet.

## 2. Static Grid Before Real Discovery

Use a static sample grid for the first visible launcher shell. Real app discovery should be designed separately because it affects metadata quality, refresh behavior, filtering, and privacy.

## 3. Activate on Launch

The app should set a regular activation policy and activate itself on launch so the window is brought forward when opened from the bundle.
