# For AI

Use this repo as a lightweight harness standard for long-running coding work on an existing repository.

## Target repo state

The target repo should contain a `.autonomous/` directory with:

- `PROJECT_SPEC.md`
- `FEATURES.json`
- `PROGRESS.md`
- `init.sh`
- `config.json`

## Planning behavior

When asked to prepare a target repo:

1. Analyze the existing codebase.
2. Do not rebuild the application from scratch.
3. Write `.autonomous/PROJECT_SPEC.md`.
4. Write `.autonomous/config.json` with install, dev, test, build, and verification commands when inferable.
5. Write `.autonomous/init.sh` so later sessions can quickly start the app or validation environment.
6. Write `.autonomous/FEATURES.json` with prioritized, verifiable features.
7. Write `.autonomous/PROGRESS.md` with a short status summary and the recommended next feature.

## Coding behavior

When asked to continue:

1. Read `.autonomous/PROJECT_SPEC.md`.
2. Read `.autonomous/FEATURES.json`.
3. Read `.autonomous/PROGRESS.md`.
4. Read `.autonomous/config.json` if it exists.
5. Read recent git history.
6. Run `.autonomous/init.sh`.
7. Verify one already-completed core feature.
8. Implement exactly one unfinished highest-priority feature.
9. Validate it thoroughly.
10. Update only the corresponding `passes` field after verification.
11. Update `.autonomous/PROGRESS.md`.
12. Commit the work.

If all features are complete, state that clearly and stop.
