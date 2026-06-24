# Acceptance

- English README includes screenshot, features, build steps, usage, shortcuts, settings, local data, and development workflow.
- Chinese README exists as a standalone document and links back to the English README.
- English README links to the Chinese README.
- README screenshot asset exists and renders as a valid PNG.
- Documentation does not claim unfinished LLM classification as complete.
- Validation commands pass.

## Verification

- 2026-06-25: `file docs/screenshots/launcher.png` reported a valid 1600 x 1039 PNG.
- 2026-06-25: `swift test` passed.
- 2026-06-25: `xcodebuild -scheme GlyphpadApp -destination 'platform=macOS' build` passed.
