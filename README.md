# Autonomous Harness

Minimal shell-based harness for long-running coding agents on existing repositories.

This repo is inspired by Anthropic's "Effective harnesses for long-running agents" idea, but kept intentionally small:

- state lives inside the target repo under `.autonomous/`
- `FEATURES.json` is the durable source of truth
- each coding session works on one unfinished feature
- `scripts/run.sh` loops until all features pass or the run stalls
- if `.autonomous/FEATURES.json` already exists, the harness skips initialization automatically

## Requirements

- `bash`
- `git`
- `jq`
- a coding AI CLI that can run non-interactively in a target repo

## Repo Layout

```text
autonomous-harness/
├── AGENTS.md
├── FOR_AI.md
├── prompts/
│   ├── coding.md
│   └── initializer.md
├── scripts/
│   ├── providers/
│   │   └── custom.sh
│   └── run.sh
└── templates/
    └── .autonomous/
        ├── FEATURES.json
        ├── PROJECT_SPEC.md
        ├── PROGRESS.md
        ├── config.example.json
        └── init.sh
```

## Fast Path For Existing Projects

1. In your existing project, ask an AI to read this repo and create `.autonomous/` using the template files as examples.
2. Review `.autonomous/FEATURES.json`.
3. Configure the provider command.
4. Run the harness once. It will keep going feature-by-feature.

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

Then start the loop:

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

The default provider is `scripts/providers/custom.sh`.

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
