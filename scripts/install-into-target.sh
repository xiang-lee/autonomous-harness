#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET=""
INSTALL_DIR=""

usage() {
  cat <<EOF
Usage:
  ./scripts/install-into-target.sh --target /absolute/path/to/repo

What it does:
  - copies the harness scaffold into <target>/.autonomous-harness/
  - does not touch the target repo's business code
  - does not create .autonomous/FEATURES.json for you

After install:
  cd <target>
  ./.autonomous-harness/scripts/run.sh
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

copy_dir_contents() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  cp -R "$src"/. "$dst"/
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unexpected argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  usage
  exit 1
fi

require_cmd realpath
TARGET="$(realpath "$TARGET")"

if [[ ! -d "$TARGET" ]]; then
  echo "Target directory does not exist: $TARGET" >&2
  exit 1
fi

if [[ ! -d "$TARGET/.git" ]]; then
  echo "Target does not look like a git repo: $TARGET" >&2
  exit 1
fi

INSTALL_DIR="$TARGET/.autonomous-harness"

mkdir -p "$INSTALL_DIR"
cp "$ROOT_DIR/AGENTS.md" "$INSTALL_DIR/AGENTS.md"
cp "$ROOT_DIR/FOR_AI.md" "$INSTALL_DIR/FOR_AI.md"
copy_dir_contents "$ROOT_DIR/prompts" "$INSTALL_DIR/prompts"
copy_dir_contents "$ROOT_DIR/scripts" "$INSTALL_DIR/scripts"
copy_dir_contents "$ROOT_DIR/templates" "$INSTALL_DIR/templates"

chmod +x "$INSTALL_DIR/scripts/"*.sh
chmod +x "$INSTALL_DIR/scripts/providers/"*.sh

echo "Installed harness scaffold into: $INSTALL_DIR"
echo
echo "Next steps:"
echo "1. In the target repo, ask an AI to create .autonomous/* using the copied scaffold."
echo "2. Review .autonomous/FEATURES.json."
echo "3. Run the harness. It will auto-detect codex, kiro-cli, or opencode when available:"
echo "   cd \"$TARGET\""
echo "   ./.autonomous-harness/scripts/run.sh"
