# AGENTS

This repository defines a long-running feature delivery workflow for existing software projects.

## When applying this harness to another repo

- Create a `.autonomous/` directory in the target repo.
- Use `templates/.autonomous/FEATURES.json` as the format example.
- Create or update:
  - `.autonomous/PROJECT_SPEC.md`
  - `.autonomous/FEATURES.json`
  - `.autonomous/PROGRESS.md`
  - `.autonomous/init.sh`
  - `.autonomous/config.json`
- For planning mode, do not implement product features yet.

## Feature list rules

- Use JSON, not Markdown, for the feature list.
- Create 15-40 prioritized, verifiable features for an existing project unless the human asks otherwise.
- Each feature should include:
  - `id`
  - `priority`
  - `category`
  - `description`
  - `steps`
  - `passes`
- All features must start with `"passes": false`.
- After the list is created, do not rewrite descriptions or steps unless the human explicitly asks for backlog refinement.
- During coding sessions, only change `passes` from `false` to `true` after verification.

## Coding session rules

- Work on one unfinished feature at a time.
- Read the project spec, feature list, progress notes, and recent git history first.
- Run the target repo's `.autonomous/init.sh` before new work.
- Verify at least one already-completed core feature before implementing a new one.
- If a regression is found, fix it before starting the next feature.
- Leave the repo in a clean state with a git commit and updated progress notes.
