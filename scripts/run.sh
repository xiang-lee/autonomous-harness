#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET=""
GOAL=""
MAX_SESSIONS=200
STALL_LIMIT=3
PROVIDER="${HARNESS_PROVIDER:-}"

infer_target() {
  if [[ -n "$TARGET" ]]; then
    return
  fi

  if [[ "$(basename "$ROOT_DIR")" == ".autonomous-harness" ]]; then
    TARGET="$(realpath "$ROOT_DIR/..")"
  fi
}

usage() {
  cat <<'EOF'
Usage:
  ./scripts/run.sh --target /absolute/path/to/repo [--goal "..."] [--provider /path/to/provider.sh]
  ./.autonomous-harness/scripts/run.sh [--goal "..."] [--provider ./.autonomous-harness/scripts/providers/codex.sh]

Options:
  --target        Absolute or relative path to the target repo
  --goal          High-level goal used only when FEATURES.json is missing or empty
  --max-sessions  Maximum coding sessions to run (default: 200)
  --stall-limit   Stop after this many no-progress sessions (default: 3)
  --provider      Provider script to execute the AI CLI
  -h, --help      Show help

Notes:
  - If .autonomous/FEATURES.json already exists and has entries, the harness skips initialization.
  - If FEATURES.json is missing or empty, provide --goal so the initializer can create the autonomous state.
  - If this script is running from a vendored `.autonomous-harness/` inside a target repo, `--target` defaults to the parent repo automatically.
  - If --provider is omitted, the harness auto-detects `codex`, `kiro-cli`, or `opencode`, then falls back to `custom.sh` when HARNESS_AI_COMMAND is set.
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

copy_if_missing() {
  local src="$1"
  local dst="$2"
  if [[ ! -e "$dst" ]]; then
    cp "$src" "$dst"
  fi
}

seed_target_state() {
  mkdir -p "$AUTONOMOUS_DIR"
  copy_if_missing "$ROOT_DIR/templates/.autonomous/PROJECT_SPEC.md" "$AUTONOMOUS_DIR/PROJECT_SPEC.md"
  copy_if_missing "$ROOT_DIR/templates/.autonomous/PROGRESS.md" "$AUTONOMOUS_DIR/PROGRESS.md"
  copy_if_missing "$ROOT_DIR/templates/.autonomous/init.sh" "$AUTONOMOUS_DIR/init.sh"
  copy_if_missing "$ROOT_DIR/templates/.autonomous/config.example.json" "$AUTONOMOUS_DIR/config.json"
  chmod +x "$AUTONOMOUS_DIR/init.sh"
}

resolve_provider() {
  if [[ -n "$PROVIDER" ]]; then
    return
  fi

  if command -v codex >/dev/null 2>&1; then
    PROVIDER="$ROOT_DIR/scripts/providers/codex.sh"
    return
  fi

  if command -v kiro-cli >/dev/null 2>&1; then
    PROVIDER="$ROOT_DIR/scripts/providers/kiro-cli.sh"
    return
  fi

  if command -v opencode >/dev/null 2>&1; then
    PROVIDER="$ROOT_DIR/scripts/providers/opencode.sh"
    return
  fi

  if [[ -n "${HARNESS_AI_COMMAND:-}" ]]; then
    PROVIDER="$ROOT_DIR/scripts/providers/custom.sh"
    return
  fi

  cat >&2 <<EOF
Could not determine which provider to use.

Either:
1. install one of: codex, kiro-cli, opencode
2. pass --provider explicitly
3. set HARNESS_AI_COMMAND so custom.sh can invoke your AI CLI
EOF
  exit 1
}

has_valid_features() {
  [[ -f "$AUTONOMOUS_DIR/FEATURES.json" ]] || return 1

  if command -v jq >/dev/null 2>&1; then
    jq -e 'type == "array" and length > 0' "$AUTONOMOUS_DIR/FEATURES.json" >/dev/null 2>&1
    return
  fi

  python3 - "$AUTONOMOUS_DIR/FEATURES.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

sys.exit(0 if isinstance(data, list) and len(data) > 0 else 1)
PY
}

count_total() {
  if command -v jq >/dev/null 2>&1; then
    jq 'length' "$AUTONOMOUS_DIR/FEATURES.json"
    return
  fi

  python3 - "$AUTONOMOUS_DIR/FEATURES.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

print(len(data))
PY
}

count_passed() {
  if command -v jq >/dev/null 2>&1; then
    jq '[.[] | select(.passes == true)] | length' "$AUTONOMOUS_DIR/FEATURES.json"
    return
  fi

  python3 - "$AUTONOMOUS_DIR/FEATURES.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

print(sum(1 for item in data if item.get("passes") is True))
PY
}

render_prompt() {
  local kind="$1"
  local session_num="$2"
  local out_file="$3"
  local passed=0
  local total=0

  if has_valid_features; then
    passed="$(count_passed)"
    total="$(count_total)"
  fi

  cat "$ROOT_DIR/prompts/${kind}.md" > "$out_file"
  cat >> "$out_file" <<EOF

---

## Runtime Context

- Harness root: $ROOT_DIR
- Target repository: $TARGET
- Session kind: $kind
- Session number: $session_num
- Current progress: $passed/$total passing
EOF

  if [[ -n "$GOAL" ]]; then
    cat >> "$out_file" <<EOF
- Requested goal: $GOAL
EOF
  fi
}

run_agent_session() {
  local kind="$1"
  local session_num="$2"
  local prompt_file

  prompt_file="$(mktemp)"
  render_prompt "$kind" "$session_num" "$prompt_file"

  echo
  echo "==> Running $kind session $session_num"
  "$PROVIDER" "$TARGET" "$prompt_file" "$kind" "$session_num"
  rm -f "$prompt_file"
}

POSITIONAL_TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --goal)
      GOAL="$2"
      shift 2
      ;;
    --max-sessions)
      MAX_SESSIONS="$2"
      shift 2
      ;;
    --stall-limit)
      STALL_LIMIT="$2"
      shift 2
      ;;
    --provider)
      PROVIDER="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$POSITIONAL_TARGET" ]]; then
        POSITIONAL_TARGET="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$TARGET" && -n "$POSITIONAL_TARGET" ]]; then
  TARGET="$POSITIONAL_TARGET"
fi

require_cmd realpath

infer_target

if [[ -z "$TARGET" ]]; then
  usage
  exit 1
fi

TARGET="$(realpath "$TARGET")"

require_cmd git
require_cmd mktemp

if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
  echo "Missing JSON parser: install jq or ensure python3 is available." >&2
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  echo "Target directory does not exist: $TARGET" >&2
  exit 1
fi

if ! git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Target is not a git repository: $TARGET" >&2
  exit 1
fi

resolve_provider

if [[ ! -x "$PROVIDER" ]]; then
  echo "Provider is not executable: $PROVIDER" >&2
  exit 1
fi

AUTONOMOUS_DIR="$TARGET/.autonomous"
seed_target_state

echo "==> Target: $TARGET"
echo "==> Autonomous dir: $AUTONOMOUS_DIR"
echo "==> Provider: $PROVIDER"

SESSION_NUM=1
STALL_COUNT=0

if ! has_valid_features; then
  if [[ -z "$GOAL" ]]; then
    cat >&2 <<EOF
No valid .autonomous/FEATURES.json found in $TARGET.

Either:
1. seed the target repo manually with your AI first, or
2. rerun with --goal so the initializer can create the autonomous state.
EOF
    exit 1
  fi

  run_agent_session initializer "$SESSION_NUM"
  SESSION_NUM=$((SESSION_NUM + 1))

  if ! has_valid_features; then
    echo "Initializer did not produce a valid .autonomous/FEATURES.json" >&2
    exit 1
  fi
fi

TOTAL="$(count_total)"
PASSED="$(count_passed)"
echo "==> Starting from $PASSED/$TOTAL passing features"

while (( SESSION_NUM <= MAX_SESSIONS + 1 )); do
  TOTAL="$(count_total)"
  PASSED="$(count_passed)"

  if (( PASSED >= TOTAL )); then
    echo
    echo "All features pass: $PASSED/$TOTAL"
    exit 0
  fi

  BEFORE="$PASSED"
  run_agent_session coding "$SESSION_NUM"

  TOTAL="$(count_total)"
  PASSED="$(count_passed)"
  echo "==> Progress after session $SESSION_NUM: $PASSED/$TOTAL"

  if (( PASSED > BEFORE )); then
    STALL_COUNT=0
  else
    STALL_COUNT=$((STALL_COUNT + 1))
    echo "==> No new passing feature this session (stall $STALL_COUNT/$STALL_LIMIT)"
  fi

  if (( STALL_COUNT >= STALL_LIMIT )); then
    echo
    echo "Stopping after $STALL_COUNT stalled sessions. Review .autonomous/PROGRESS.md and recent commits."
    exit 2
  fi

  SESSION_NUM=$((SESSION_NUM + 1))
done

echo "Reached max sessions limit: $MAX_SESSIONS"
exit 3
