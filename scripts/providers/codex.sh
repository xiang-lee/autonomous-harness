#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
PROMPT_FILE="${2:-}"
SESSION_KIND="${3:-coding}"
SESSION_NUM="${4:-0}"

if [[ -z "$TARGET" || -z "$PROMPT_FILE" ]]; then
  echo "usage: codex.sh <target> <prompt-file> [session-kind] [session-num]" >&2
  exit 1
fi

BIN="${CODEX_BIN:-codex}"
APPROVAL="${CODEX_APPROVAL:-never}"
SANDBOX="${CODEX_SANDBOX:-workspace-write}"

CMD=("$BIN" exec --cd "$TARGET" --ask-for-approval "$APPROVAL" --sandbox "$SANDBOX")

if [[ "${CODEX_SKIP_GIT_REPO_CHECK:-0}" == "1" ]]; then
  CMD+=(--skip-git-repo-check)
fi

if [[ -n "${CODEX_MODEL:-}" ]]; then
  CMD+=(--model "$CODEX_MODEL")
fi

if [[ -n "${CODEX_PROFILE:-}" ]]; then
  CMD+=(--profile "$CODEX_PROFILE")
fi

if [[ -n "${CODEX_EXTRA_ARGS:-}" ]]; then
  eval "CMD+=( ${CODEX_EXTRA_ARGS} )"
fi

CMD+=(-)

echo "==> Codex provider"
printf 'session=%s number=%s\n' "$SESSION_KIND" "$SESSION_NUM"
printf 'command='; printf '%q ' "${CMD[@]}"; printf '\n'

"${CMD[@]}" < "$PROMPT_FILE"
