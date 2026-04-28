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

function sync_playbook() {
  if [ -d "$TARGET_DIR" ]; then
    echo "⚠️ $TARGET_DIR already exists"
    exit 1
  fi

  echo "📦 Copying AI Playbook..."
  cp -r "$AI_PLAYBOOK_SOURCE" "$TARGET_DIR"

  echo "📝 Creating manifest..."
  find "$TARGET_DIR" -type f | sed "s|$TARGET_DIR/||" > "$MANIFEST_FILE"

  echo "✅ Playbook copied successfully"
}

case "$COMMAND" in
  sync)
    sync_playbook
    ;;
  *)
    echo "Usage: ai-playbook {copy|sync|status}"
    exit 1
    ;;
esac

echo ""
echo "🚑  FirstAid finished ⚕️"
echo "───────────────────────────────────────────────────────────────"