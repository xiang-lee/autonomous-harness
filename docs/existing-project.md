# Existing Project Workflow

This is the intended user journey for applying the harness to an existing repository.

## 1. Prepare the target repo

In the target repository:

```bash
cd /absolute/path/to/existing-project
git checkout -b ai/autonomous-run
```

Using a dedicated branch keeps the long-running work isolated.

## 2. Ask an AI to create the autonomous state

Give your AI this prompt in the target repo:

```text
Use this repository as the workflow standard:
<autonomous-harness repo link>

In this repository, create `.autonomous/` with:
- `.autonomous/PROJECT_SPEC.md`
- `.autonomous/FEATURES.json`
- `.autonomous/PROGRESS.md`
- `.autonomous/init.sh`
- `.autonomous/config.json`

Rules:
- Do not implement product features yet.
- Analyze the existing codebase first.
- Create 15-40 prioritized, verifiable features.
- Every feature must start with "passes": false.
- Use the JSON structure shown in the harness template.
```

If you want the harness itself to do initialization later, you can skip this step and pass `--goal` to `run.sh`. But the simplest path is usually to seed the feature list first, review it, then run the loop.

## 3. Review the generated feature list

Open `.autonomous/FEATURES.json` and look for:

- missing important features
- features that are too large for one session
- bad priority ordering
- risky or unwanted tasks

If needed, ask the AI to refine the backlog before starting implementation.

## 4. Pick a provider

This repo includes ready-to-use provider scripts:

- `scripts/providers/codex.sh`
- `scripts/providers/kiro-cli.sh`
- `scripts/providers/opencode.sh`
- `scripts/providers/custom.sh`

### Codex example

```bash
cd /absolute/path/to/autonomous-harness
./scripts/run.sh \
  --target "/absolute/path/to/existing-project" \
  --provider "./scripts/providers/codex.sh"
```

### Kiro example

```bash
cd /absolute/path/to/autonomous-harness
./scripts/run.sh \
  --target "/absolute/path/to/existing-project" \
  --provider "./scripts/providers/kiro-cli.sh"
```

### OpenCode example

```bash
cd /absolute/path/to/autonomous-harness
./scripts/run.sh \
  --target "/absolute/path/to/existing-project" \
  --provider "./scripts/providers/opencode.sh"
```

## 5. Let the loop run

Each session should:

- read `.autonomous/PROJECT_SPEC.md`
- read `.autonomous/FEATURES.json`
- read `.autonomous/PROGRESS.md`
- read `.autonomous/config.json` if present
- run `.autonomous/init.sh`
- verify one previously completed core feature
- implement exactly one unfinished highest-priority feature
- verify it
- update only the relevant `passes` field
- update `.autonomous/PROGRESS.md`
- commit the work

The harness then starts the next session automatically.

## 6. Stop and resume

- Stop with `Ctrl+C`
- Resume with the same `run.sh` command

Because state is stored in the target repo, the harness continues from the saved `.autonomous/` files and git history.

## 7. If the target repo is not seeded yet

You can let the harness initialize the state if you provide `--goal`:

```bash
./scripts/run.sh \
  --target "/absolute/path/to/existing-project" \
  --provider "./scripts/providers/codex.sh" \
  --goal "Implement feature A, feature B, and feature C incrementally"
```

Behavior:

- valid `FEATURES.json` already exists -> initializer is skipped automatically
- missing or empty `FEATURES.json` + `--goal` -> initializer runs once, then coding loop begins
- missing or empty `FEATURES.json` without `--goal` -> harness stops and asks you to seed the repo first
