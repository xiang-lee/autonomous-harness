# Autonomous Harness

Minimal shell-based harness for long-running coding agents on existing repositories.

This repo is inspired by Anthropic's "Effective harnesses for long-running agents" idea, but kept intentionally small:

- state lives inside the target repo under `.autonomous/`
- `FEATURES.json` is the durable source of truth
- each coding session works on one unfinished feature
- `scripts/run.sh` loops until all features pass or the run stalls
- if `.autonomous/FEATURES.json` already exists, the harness skips initialization automatically

Recommended usage is now scaffold mode:

- treat this repo as a scaffold template
- copy it into an existing repo as `./.autonomous-harness/`
- run the harness from inside that existing repo

## Minimal Prompt

In an existing project, you should usually only need to tell another AI:

```text
Use https://github.com/xiang-lee/autonomous-harness.
Read its README and apply the scaffold workflow in this repository.
Do not implement product features yet. Stop after creating `.autonomous-harness/`, `.autonomous/`, and `.autonomous/FEATURES.json` so I can review.
```

This README is intentionally written so an AI can follow it directly.

## AI Operating Instructions

If you are an AI reading this README while working inside another existing repository, do this in the current repository:

1. Copy this harness into `./.autonomous-harness/`.
2. Copy or recreate:
   - `AGENTS.md`
   - `FOR_AI.md`
   - `prompts/`
   - `scripts/`
   - `templates/`
3. Create:
   - `.autonomous/PROJECT_SPEC.md`
   - `.autonomous/FEATURES.json`
   - `.autonomous/PROGRESS.md`
   - `.autonomous/init.sh`
   - `.autonomous/config.json`
4. Analyze the existing codebase before writing those files.
5. Do not rebuild the app from scratch.
6. Do not implement product features yet unless the human explicitly asks you to continue.
7. Create 15-40 prioritized, verifiable features.
8. Every feature must start with `"passes": false`.
9. After the human reviews the feature list, continue by running `./.autonomous-harness/scripts/run.sh` from the current repository.
10. If `codex`, `kiro-cli`, or `opencode` is installed, `run.sh` auto-detects it. Otherwise use `--provider` or `HARNESS_AI_COMMAND`.

## Requirements

- `bash`
- `git`
- `jq` or `python3`
- a coding AI CLI that can run non-interactively in a target repo

## Status

Current local repo state:

- shell harness created
- prompts and `.autonomous/` templates created
- provider scripts included for `custom`, `codex`, `kiro-cli`, and `opencode`
- install script included for scaffold mode
- local git repo initialized and published

## Repo Layout

```text
autonomous-harness/
├── AGENTS.md
├── FOR_AI.md
├── docs/
│   └── existing-project.md
├── prompts/
│   ├── coding.md
│   └── initializer.md
├── scripts/
│   ├── providers/
│   │   ├── codex.sh
│   │   ├── custom.sh
│   │   ├── kiro-cli.sh
│   │   └── opencode.sh
│   ├── install-into-target.sh
│   └── run.sh
└── templates/
    └── .autonomous/
        ├── FEATURES.json
        ├── PROJECT_SPEC.md
        ├── PROGRESS.md
        ├── config.example.json
        └── init.sh
```

## Recommended Workflow: Use This Repo As A Scaffold

Preferred flow:

1. In your existing project, ask an AI to read this repo and copy the scaffold into `./.autonomous-harness/`.
2. In that same existing project, ask the AI to create `.autonomous/` using the copied template files.
3. Review `.autonomous/FEATURES.json`.
4. Run the vendored harness from inside the existing project.

Example AI instruction:

```text
Read this repository and use it as a scaffold:
https://github.com/xiang-lee/autonomous-harness

In the current repository:
1. Copy this harness into `./.autonomous-harness/`.
   Copy or recreate:
   - `AGENTS.md`
   - `FOR_AI.md`
   - `prompts/`
   - `scripts/`
   - `templates/`
2. Create `.autonomous/PROJECT_SPEC.md`, `.autonomous/FEATURES.json`, `.autonomous/PROGRESS.md`, `.autonomous/init.sh`, and `.autonomous/config.json`.
3. Do not implement product features yet.
4. Create 15-40 prioritized, verifiable features.
5. Every feature must start with `"passes": false`.
```

Then, if you want a second AI step before implementation, use the local scaffold rather than the GitHub link:

```text
Use the copied scaffold in `./.autonomous-harness/` as the workflow standard.

In this repository, create:
- `.autonomous/PROJECT_SPEC.md`
- `.autonomous/FEATURES.json`
- `.autonomous/PROGRESS.md`
- `.autonomous/init.sh`
- `.autonomous/config.json`

Rules:
- Do not implement product features yet.
- Analyze the existing codebase first.
- Create 15-40 prioritized, verifiable features.
- Every feature must start with `"passes": false`.
```

Then run the harness directly inside the target repo:

```bash
cd /absolute/path/to/existing-project

./.autonomous-harness/scripts/run.sh
```

Because the harness is installed as `./.autonomous-harness/`, `run.sh` automatically uses the parent repo as the target.
If `codex`, `kiro-cli`, or `opencode` is available, it auto-selects the matching provider.

## Manual Scaffold Install

If you want to copy the scaffold yourself instead of asking an AI to do it:

```bash
cd /absolute/path/to/autonomous-harness

./scripts/install-into-target.sh --target "/absolute/path/to/existing-project"
```

After that:

```bash
cd /absolute/path/to/existing-project
./.autonomous-harness/scripts/run.sh
```

## Central Runner Mode

1. In your existing project, ask an AI to read this repo and create `.autonomous/` using the template files as examples.
2. Review `.autonomous/FEATURES.json`.
3. Configure the provider command.
4. Run the harness once. It will keep going feature-by-feature.

Full step-by-step guide: `docs/existing-project.md`

Example prompt for the planning step:

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
- Create 15-40 prioritized, verifiable feature entries.
- Every feature must start with "passes": false.
- Use the JSON structure shown in the harness template.
```

Then start the loop from the central harness checkout:

```bash
export HARNESS_AI_COMMAND='your-ai-cli --cwd "{{TARGET}}" --prompt-file "{{PROMPT_FILE}}"'

./scripts/run.sh --target "/absolute/path/to/existing-project"
```

## One-Command Auto Init

If the target repo does not have `.autonomous/FEATURES.json` yet, you can let the harness create it first:

```bash
export HARNESS_AI_COMMAND='your-ai-cli --cwd "{{TARGET}}" --prompt-file "{{PROMPT_FILE}}"'

./scripts/run.sh \
  --target "/absolute/path/to/existing-project" \
  --goal "Implement feature A, feature B, and feature C incrementally"
```

Behavior:

- valid `FEATURES.json` exists -> start coding loop immediately
- missing or empty `FEATURES.json` + `--goal` -> run initializer once, then start coding loop
- missing or empty `FEATURES.json` without `--goal` -> stop and tell you to seed the target repo first

## Provider Setup

If you do not pass `--provider`, `run.sh` auto-detects providers in this order:

1. `codex`
2. `kiro-cli`
3. `opencode`
4. `custom.sh` when `HARNESS_AI_COMMAND` is set

The explicit fallback provider is `scripts/providers/custom.sh`.

It reads `HARNESS_AI_COMMAND`, substitutes placeholders, then executes it.

Supported placeholders:

- `{{TARGET}}`
- `{{PROMPT_FILE}}`
- `{{SESSION_KIND}}`
- `{{SESSION_NUM}}`

Example:

```bash
export HARNESS_AI_COMMAND='your-ai-cli --cwd "{{TARGET}}" --prompt-file "{{PROMPT_FILE}}"'
```

If your CLI reads prompts from stdin instead of a file, you can still use the same hook:

```bash
export HARNESS_AI_COMMAND='sh -lc '\''cd "{{TARGET}}" && your-ai-cli < "{{PROMPT_FILE}}"'\''' 
```

You can also pass a custom provider script:

```bash
./scripts/run.sh --target "/path/to/repo" --provider "/path/to/provider.sh"
```

Included providers:

- `scripts/providers/custom.sh`
- `scripts/providers/codex.sh`
- `scripts/providers/kiro-cli.sh`
- `scripts/providers/opencode.sh`

### Codex

Based on OpenAI Codex CLI non-interactive mode with `codex exec`.

```bash
./scripts/run.sh \
  --target "/absolute/path/to/existing-project" \
  --provider "./scripts/providers/codex.sh"
```

Optional env:

```bash
export CODEX_BIN=codex
export CODEX_MODEL=gpt-5-codex
export CODEX_APPROVAL=never
export CODEX_SANDBOX=workspace-write
```

### Kiro CLI

Based on `kiro-cli chat --no-interactive`.

```bash
./scripts/run.sh \
  --target "/absolute/path/to/existing-project" \
  --provider "./scripts/providers/kiro-cli.sh"
```

Optional env:

```bash
export KIRO_BIN=kiro-cli
export KIRO_AGENT=
export KIRO_TRUST_MODE=all
```

### OpenCode

Based on `opencode run` with stdin prompt input.

```bash
./scripts/run.sh \
  --target "/absolute/path/to/existing-project" \
  --provider "./scripts/providers/opencode.sh"
```

Optional env:

```bash
export OPENCODE_BIN=opencode
export OPENCODE_MODEL=
export OPENCODE_AGENT=
export OPENCODE_VARIANT=
```

## Existing Project User Journey

Short version:

1. Open your existing repo on a branch.
2. Ask an AI to copy this repo into `./.autonomous-harness/` in that repo.
3. Ask the AI to create `.autonomous/` using the copied harness.
4. Review `.autonomous/FEATURES.json`.
5. Usually just run `./.autonomous-harness/scripts/run.sh` once.
6. If you need a specific CLI, pass `--provider ...` explicitly.
7. Let it continue until all features pass or the run stalls.
8. Pause with `Ctrl+C`, resume with the same command.

Detailed walkthrough: `docs/existing-project.md`

## What The Harness Does Each Session

For every coding session, the prompt instructs the agent to:

- read `.autonomous/PROJECT_SPEC.md`
- read `.autonomous/FEATURES.json`
- read `.autonomous/PROGRESS.md`
- read `.autonomous/config.json` if present
- read recent git history
- run `.autonomous/init.sh`
- verify one already-completed core feature
- implement exactly one unfinished highest-priority feature
- validate it through the strongest available path
- update only the relevant `passes` field
- update `.autonomous/PROGRESS.md`
- commit the work in a clean state

## Pause And Resume

- Stop the loop with `Ctrl+C`
- Resume later with the same command

Because progress lives in the target repo, the harness can continue from where it left off.

## Notes

- Start from a dedicated git branch in the target repo.
- Review the generated feature list before long runs when possible.
- Browser automation is ideal for web apps, but the prompts also allow fallback validation if your AI runtime does not expose browser tools.
