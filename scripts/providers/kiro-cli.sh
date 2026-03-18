#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
PROMPT_FILE="${2:-}"
SESSION_KIND="${3:-coding}"
SESSION_NUM="${4:-0}"

if [[ -z "$TARGET" || -z "$PROMPT_FILE" ]]; then
  echo "usage: kiro-cli.sh <target> <prompt-file> [session-kind] [session-num]" >&2
  exit 1
fi

BIN="${KIRO_BIN:-kiro-cli}"
PROMPT="$(<"$PROMPT_FILE")"
CMD=("$BIN" chat --no-interactive)

if [[ -n "${KIRO_AGENT:-}" ]]; then
  CMD+=(--agent "$KIRO_AGENT")
fi

if [[ "${KIRO_TRUST_MODE:-all}" == "all" ]]; then
  CMD+=(--trust-all-tools)
fi

if [[ -n "${KIRO_TRUST_TOOLS:-}" ]]; then
  CMD+=(--trust-tools "$KIRO_TRUST_TOOLS")
fi

if [[ "${KIRO_REQUIRE_MCP_STARTUP:-0}" == "1" ]]; then
  CMD+=(--require-mcp-startup)
fi

if [[ -n "${KIRO_EXTRA_ARGS:-}" ]]; then
  eval "CMD+=( ${KIRO_EXTRA_ARGS} )"
fi

echo "==> Kiro CLI provider"
printf 'session=%s number=%s\n' "$SESSION_KIND" "$SESSION_NUM"
printf 'command='; printf '%q ' "${CMD[@]}"; printf '\n'

(
  cd "$TARGET"
  "${CMD[@]}" "$PROMPT"
)
