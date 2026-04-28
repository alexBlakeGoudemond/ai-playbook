#!/usr/bin/env bash

# --------------------------------------------------------------------------------------------------------
# ai-playbook-alignment: bring markdown files from a source directory to a target directory, with sync and status features
# For fun, we named this little tool as `firstaid` because it assists in keeping your repository healthy and up-to-date!
# Usage: firstaid sync
#
# Bash insights:
# - has custom defined functions which are invoked without parentheses, for example: `sync`
# --------------------------------------------------------------------------------------------------------

set -e # exit if anything fails

ALIAS_VERSION="1.0.0"

echo ""
echo "🚑  FirstAid $ALIAS_VERSION — AI Playbook ⚕️"
echo "───────────────────────────────────────────────────────────────"

COMMAND=$1
TARGET_DIR=".ai-playbook"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_PLAYBOOK_SOURCE="$(cd "$SCRIPT_DIR/../.." && pwd)"

PLAYBOOK_DIRS=(".ai" "prompts" "workflows")

function sync_playbook() {
  echo "🔍 Source: $AI_PLAYBOOK_SOURCE"
  echo "📁 Target: $TARGET_DIR"

  # Safety checks
  if [ -z "$AI_PLAYBOOK_SOURCE" ] || [ "$AI_PLAYBOOK_SOURCE" = "/" ]; then
    echo "❌ Invalid source directory"
    exit 1
  fi

  if [ -z "$TARGET_DIR" ] || [ "$TARGET_DIR" = "/" ]; then
    echo "❌ Invalid target directory"
    exit 1
  fi

  if [ -d "$TARGET_DIR" ]; then
    echo "🧹 Removing existing $TARGET_DIR..."
    rm -rf "$TARGET_DIR"
  fi

  mkdir -p "$TARGET_DIR"

  echo "✒️  Copying selected AI Playbook components..."
  copy_playbook
  echo "✅  Playbook synced successfully"
}

function copy_playbook() {
  for dir in "${PLAYBOOK_DIRS[@]}"; do
    if [ -d "$AI_PLAYBOOK_SOURCE/$dir" ]; then
      echo "  → Copying $dir"
      cp -r "$AI_PLAYBOOK_SOURCE/$dir" "$TARGET_DIR/"
    else
      echo "  ⚠️ Skipping missing directory: $dir"
    fi
  done
}

case "$COMMAND" in
  sync)
    sync_playbook
    ;;
  *)
    echo "Usage: firstaid {sync}"
    exit 1
    ;;
esac

echo ""
echo "🚑  FirstAid finished ⚕️"
echo "───────────────────────────────────────────────────────────────"