# Decisions

## 1. Development Starts With Planning

Development will not begin until the workflow and first product scope are documented. This prevents the project from turning into a generic launcher before the Launchpad replacement goal is clear.

## 2. Spaces Are Required for Meaningful Iterations

Each meaningful requirement gets a folder under `spaces/YYYY-MM-DD-short-requirement-name/`.

Spaces are for product, architecture, and implementation work with real scope. They are not required for tiny copy edits or formatting-only changes.

## 3. Branches Follow Requirement Scope

Use `codex/YYYY-MM-DD-short-task` branches for meaningful requirements. Keep `main` stable and use `dev` as the integration branch once development starts.

## 4. One Requirement, One Commit

Each completed requirement should end with one scoped Conventional Commit. Avoid bundling unrelated behavior in the same commit.

## 5. SQLite Is the Local Data Store

Glyphpad will use SQLite for local persistence. It should store app records, categories, folders, page layout, classification suggestions, user decisions, provider settings, and migration state.

The UI should not talk to SQLite directly. Persistence should sit behind repository or service boundaries.

## 6. LLM Classification Is Assistive

Model-backed classification should suggest organization, not silently overwrite user choices. The default flow should be review-first.

## 7. Privacy Must Be Designed Early

Before remote model calls exist, the project must define which metadata can be sent, how users preview it, and how they disable remote classification.
