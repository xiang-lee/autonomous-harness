# For AI

Use this repo as a lightweight harness standard for long-running coding work on an existing repository.

If you can only read one file from this repo, read `README.md`. It contains the full scaffold workflow and the minimal instructions a human can give you.

## Scaffold mode

If you are working inside an existing target repo and this GitHub repo is only a reference, treat this repo as a scaffold.

In the target repo, create `./.autonomous-harness/` and copy or recreate these files from this repo into it:

- `AGENTS.md`
- `FOR_AI.md`
- `prompts/`
- `scripts/`
- `templates/`

Then run the vendored harness from the target repo itself.

Example:

```bash
./.autonomous-harness/scripts/run.sh
```

When `run.sh` is executed from `./.autonomous-harness/` inside a target repo, it should treat the parent repo as the target automatically.
If `codex`, `kiro-cli`, or `opencode` is installed, `run.sh` should auto-detect it.

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

If `./.autonomous-harness/` is not present yet, create it first from this scaffold before preparing `.autonomous/`.

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
