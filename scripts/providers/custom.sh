#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
PROMPT_FILE="${2:-}"
SESSION_KIND="${3:-coding}"
SESSION_NUM="${4:-0}"

if [[ -z "$TARGET" || -z "$PROMPT_FILE" ]]; then
  echo "usage: custom.sh <target> <prompt-file> [session-kind] [session-num]" >&2
  exit 1
fi

if [[ -z "${HARNESS_AI_COMMAND:-}" ]]; then
  cat >&2 <<'EOF'
HARNESS_AI_COMMAND is not set.

Example:
  export HARNESS_AI_COMMAND='your-ai-cli --cwd "{{TARGET}}" --prompt-file "{{PROMPT_FILE}}"'
EOF
  exit 1
fi

COMMAND="$HARNESS_AI_COMMAND"
COMMAND="${COMMAND//\{\{TARGET\}\}/$TARGET}"
COMMAND="${COMMAND//\{\{PROMPT_FILE\}\}/$PROMPT_FILE}"
COMMAND="${COMMAND//\{\{SESSION_KIND\}\}/$SESSION_KIND}"
COMMAND="${COMMAND//\{\{SESSION_NUM\}\}/$SESSION_NUM}"

echo "==> Provider command"
echo "$COMMAND"
eval "$COMMAND"
