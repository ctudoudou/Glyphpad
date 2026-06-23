# Decisions

## 1. Start With a Swift Package

Use Swift Package Manager for the first implementation baseline. This keeps core logic testable before creating a full Xcode app project or packaging pipeline.

## 2. Keep UI and Persistence Separate

The first UI entry point must not talk to SQLite directly. Persistence is exposed through repository types so later app screens can share the same boundary.

## 3. SQLite Schema Is Versioned From the Start

The database will include a small metadata table with a schema version. This prevents early throwaway persistence code from becoming an untracked migration problem.

## 4. App Discovery Comes Later

This iteration stores app records but does not scan the system. Scanning deserves a separate space because it touches macOS metadata APIs, permissions, filtering, and refresh behavior.
