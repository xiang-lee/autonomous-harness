#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
PROMPT_FILE="${2:-}"
SESSION_KIND="${3:-coding}"
SESSION_NUM="${4:-0}"

if [[ -z "$TARGET" || -z "$PROMPT_FILE" ]]; then
  echo "usage: opencode.sh <target> <prompt-file> [session-kind] [session-num]" >&2
  exit 1
fi

BIN="${OPENCODE_BIN:-opencode}"
CMD=("$BIN" run --dir "$TARGET")

if [[ -n "${OPENCODE_MODEL:-}" ]]; then
  CMD+=(--model "$OPENCODE_MODEL")
fi

if [[ -n "${OPENCODE_AGENT:-}" ]]; then
  CMD+=(--agent "$OPENCODE_AGENT")
fi

if [[ -n "${OPENCODE_VARIANT:-}" ]]; then
  CMD+=(--variant "$OPENCODE_VARIANT")
fi

if [[ -n "${OPENCODE_ATTACH:-}" ]]; then
  CMD+=(--attach "$OPENCODE_ATTACH")
fi

if [[ -n "${OPENCODE_PASSWORD:-}" ]]; then
  CMD+=(--password "$OPENCODE_PASSWORD")
fi

if [[ -n "${OPENCODE_EXTRA_ARGS:-}" ]]; then
  eval "CMD+=( ${OPENCODE_EXTRA_ARGS} )"
fi

echo "==> OpenCode provider"
printf 'session=%s number=%s\n' "$SESSION_KIND" "$SESSION_NUM"
printf 'command='; printf '%q ' "${CMD[@]}"; printf '\n'

"${CMD[@]}" < "$PROMPT_FILE"
