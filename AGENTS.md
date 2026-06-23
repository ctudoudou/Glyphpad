# Glyphpad Development Guide

Glyphpad is a macOS 26+ Launchpad replacement. The product goal is to preserve the core native Launchpad experience while adding a separate control panel for app organization, automatic classification, and LLM-assisted workflows.

## Product Principles

- Match the native macOS mental model first: full-screen app grid, search, folders, pages, drag organization, and fast keyboard interaction.
- Keep the control panel separate from the launcher surface. The launcher should feel immediate; configuration belongs in settings.
- Prefer local-first behavior. App metadata, layout, categories, classification history, and user decisions are stored locally.
- Treat LLM classification as assistive, not authoritative. The user should be able to preview, edit, accept, reject, or disable model suggestions.
- Avoid sending sensitive local data to model providers by default. Any remote classification flow must make its payload explicit.

## Technical Baseline

- Platform: native macOS app.
- Language and UI: Swift + SwiftUI, with AppKit where system-level behavior requires it.
- Data store: SQLite.
- Data access: keep persistence behind a repository/service boundary so the UI does not build SQL directly.
- App discovery: use macOS application metadata APIs where possible, with filesystem scanning as a fallback only when needed.
- LLM providers: implement behind a provider abstraction. Start with an OpenAI-compatible provider shape, but avoid hard-coding one vendor into product logic.

## Branch Management

- `main`: stable, releasable baseline.
- `dev`: integration branch for accepted work.
- `codex/YYYY-MM-DD-short-task`: task branches for each meaningful requirement.

Use one Conventional Commit per completed requirement:

- `feat:` user-facing feature
- `fix:` bug fix
- `docs:` planning, requirements, or documentation
- `chore:` tooling, project setup, build configuration
- `test:` test-only changes
- `refactor:` structure changes without intended behavior changes

Do not mix unrelated requirements in one commit.

## Spaces Workflow

Meaningful iterations must have a space under:

```text
spaces/YYYY-MM-DD-short-requirement-name/
```

Each space should include:

- `README.md`: background, goals, non-goals, and scope.
- `TODO.md`: concrete task checklist for the iteration.
- `decisions.md`: product and technical decisions made during the iteration.
- `acceptance.md`: acceptance criteria used to decide whether the work is complete.

Only create a space for product, architecture, or implementation work that can drift without a written boundary. Do not create spaces for tiny copy edits, formatting-only changes, or throwaway experiments.

## Requirement Discipline

- Start each iteration by updating or creating the relevant space.
- Keep implementation aligned with the current space's goals and non-goals.
- If the desired behavior changes, update `decisions.md` before changing code.
- If a task grows too broad, split it into a new space instead of expanding the current one indefinitely.
- Finish a requirement by checking `acceptance.md`, running relevant tests, and making one scoped commit.

## Testing Expectations

- Tests are expected by default once code exists.
- Persistence logic should have unit tests around migrations, repository behavior, and classification history.
- Classification logic should be tested with deterministic fixtures before any LLM provider is involved.
- UI behavior should be covered at the highest practical level for the chosen macOS test stack.
- Manual verification notes should be recorded in the active space when behavior depends on macOS UI integration.

## Initial Roadmap

1. Project planning and workflow.
2. MVP product scope.
3. Technical architecture and SQLite schema direction.
4. Native Launchpad-like UI specification.
5. Manual app organization.
6. Automatic classification engine.
7. LLM-assisted classification.
8. Control panel and provider settings.
9. Packaging, signing, and release flow.
