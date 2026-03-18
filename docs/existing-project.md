# Existing Project Workflow

This is the intended user journey for applying the harness to an existing repository.

Preferred approach: install the harness inside the target repo as `./.autonomous-harness/`, then run it locally from there.

Minimal instruction you can usually give an AI in the target repo:

```text
Use https://github.com/xiang-lee/autonomous-harness.
Read its README and apply the scaffold workflow in this repository.
Do not implement product features yet. Stop after creating `.autonomous-harness/`, `.autonomous/`, and `.autonomous/FEATURES.json` so I can review.
```

## 1. Prepare the target repo

In the target repository:

```bash
cd /absolute/path/to/existing-project
git checkout -b ai/autonomous-run
```

Using a dedicated branch keeps the long-running work isolated.

## 2. Ask an AI to copy the scaffold into the current repo

Give your AI this prompt in the target repo:

```text
Read this repository and use it as a scaffold:
https://github.com/xiang-lee/autonomous-harness

In the current repository, create `./.autonomous-harness/` and copy or recreate:
- `AGENTS.md`
- `FOR_AI.md`
- `prompts/`
- `scripts/`
- `templates/`

Do not implement product features yet.
```

At the end of this step, your target repo should contain:

```text
existing-project/
  .autonomous-harness/
    AGENTS.md
    FOR_AI.md
    prompts/
    scripts/
    templates/
```

You can also do this manually:

```bash
cd /absolute/path/to/autonomous-harness
./scripts/install-into-target.sh --target "/absolute/path/to/existing-project"
```

## 3. Ask an AI to create the autonomous state

Give your AI this prompt in the target repo:

```text
Use the copied scaffold in `./.autonomous-harness/` as the workflow standard.

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

## 4. Review the generated feature list

Open `.autonomous/FEATURES.json` and look for:

- missing important features
- features that are too large for one session
- bad priority ordering
- risky or unwanted tasks

If needed, ask the AI to refine the backlog before starting implementation.

## 5. Pick a provider

The vendored harness includes ready-to-use provider scripts:

- `.autonomous-harness/scripts/providers/codex.sh`
- `.autonomous-harness/scripts/providers/kiro-cli.sh`
- `.autonomous-harness/scripts/providers/opencode.sh`
- `.autonomous-harness/scripts/providers/custom.sh`

In most cases you can just run `./.autonomous-harness/scripts/run.sh` and let it auto-detect the available CLI.

### Codex example

```bash
cd /absolute/path/to/existing-project
./.autonomous-harness/scripts/run.sh
```

### Kiro example

```bash
cd /absolute/path/to/existing-project
./.autonomous-harness/scripts/run.sh
```

### OpenCode example

```bash
cd /absolute/path/to/existing-project
./.autonomous-harness/scripts/run.sh
```

If more than one supported CLI is installed, or if you want to force a specific one, pass `--provider` explicitly.

## 6. Let the loop run

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

## 7. Stop and resume

- Stop with `Ctrl+C`
- Resume with the same `./.autonomous-harness/scripts/run.sh` command

Because state is stored in the target repo, the harness continues from the saved `.autonomous/` files and git history.

## 8. If the target repo is not seeded yet

You can let the harness initialize the state if you provide `--goal`:

```bash
cd /absolute/path/to/existing-project
./.autonomous-harness/scripts/run.sh \
  --provider ./.autonomous-harness/scripts/providers/codex.sh \
  --goal "Implement feature A, feature B, and feature C incrementally"
```

Behavior:

- valid `FEATURES.json` already exists -> initializer is skipped automatically
- missing or empty `FEATURES.json` + `--goal` -> initializer runs once, then coding loop begins
- missing or empty `FEATURES.json` without `--goal` -> harness stops and asks you to seed the repo first
