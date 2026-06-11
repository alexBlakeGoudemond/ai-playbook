#!/usr/bin/env bash

# --------------------------------------------------------------------------------------------------------
# ai-playbook-alignment: bring markdown files from a source directory to a target directory, with sync and status features
# For fun, we named this little tool as `firstaid` because it assists in keeping your repository healthy and up-to-date!
# Usage: firstaid sync
# Usage: firstaid remove
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
TARGET_STANDALONE_FILES_DESTINATION=".ai-playbook/.."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_PLAYBOOK_SOURCE="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load .env file if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
  # Use a simple parser instead of sourcing to avoid path issues with backslashes
  AI_PLAYBOOK_PATH=$(grep "^AI_PLAYBOOK_PATH=" "$SCRIPT_DIR/.env" | cut -d'=' -f2- | sed "s/^['\"]//;s/['\"]$//")
fi

PLAYBOOK_DIRS=("instructions" "prompts" "workflows")
STANDALONE_FILES=("AGENTS.playbook.md")

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
  copy_standalone_files
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

function copy_standalone_files() {
  for file in "${STANDALONE_FILES[@]}"; do
    if [ -f "$AI_PLAYBOOK_SOURCE/$file" ]; then
      echo "  → Copying $file"
      cp "$AI_PLAYBOOK_SOURCE/$file" "$TARGET_STANDALONE_FILES_DESTINATION"
    else
      echo "  ⚠️ Skipping missing file: $file"
    fi
  done
}

function remove_playbook() {
  echo "🧹 Removing AI Playbook..."

  for file in "${STANDALONE_FILES[@]}"; do
    if [ -f "$AI_PLAYBOOK_SOURCE/$file" ]; then
      echo "  → Removing $file"
      rm -f "$TARGET_STANDALONE_FILES_DESTINATION/$file"
    else
      echo "  ⚠️ Skipping missing file: $file"
    fi
  done

  if [ -d "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
    rm -rf "$TARGET_DIR"
    echo "  → Removed $TARGET_DIR"
  else
    echo "  ⚠️ $TARGET_DIR does not exist"
  fi

  echo "✅ Remove complete"
}

function link_playbook() {
  echo "🔗 Linking to Global AI Playbook..."

  # Try direct cmd.exe first (works in Git Bash and some WSL setups)
  # Windows mklink /J requires the destination and then the source
  WIN_TARGET_DIR=$(cygpath -w "$(pwd)/$TARGET_DIR" 2>/dev/null || wslpath -w "$(pwd)/$TARGET_DIR" 2>/dev/null || echo "$(pwd | sed 's/^\/\([a-z]\)\//\1:\\/')\\$TARGET_DIR")
  WIN_SOURCE_DIR=$(cygpath -w "$AI_PLAYBOOK_PATH" 2>/dev/null || wslpath -w "$AI_PLAYBOOK_PATH" 2>/dev/null || echo "$AI_PLAYBOOK_PATH" | sed 's/^\/\([a-z]\)\//\1:\\/')

  if [ -n "$WIN_TARGET_DIR" ] && [ -n "$WIN_SOURCE_DIR" ]; then
    echo "  → Attempting to create junction: $WIN_TARGET_DIR -> $WIN_SOURCE_DIR"
    if cmd.exe /c "mklink /J \"$WIN_TARGET_DIR\" \"$WIN_SOURCE_DIR\"" 2>/dev/null || \
       /c/Windows/System32/cmd.exe /c "mklink /J \"$WIN_TARGET_DIR\" \"$WIN_SOURCE_DIR\"" 2>/dev/null || \
       cmd /c "mklink /J \"$WIN_TARGET_DIR\" \"$WIN_SOURCE_DIR\"" 2>/dev/null; then
      echo "✅ Playbook linked successfully"
      return 0
    fi
  fi

  # Fallback to Python delegation
  echo "  → Attempting delegation to firstaid.py..."
  
  # Try to find a Windows python executable if we are in WSL
  PYTHON_EXE="python"
  if command -v python.exe >/dev/null 2>&1; then
    PYTHON_EXE="python.exe"
  elif command -v py.exe >/dev/null 2>&1; then
    PYTHON_EXE="py.exe"
  fi

  # Convert script path for Windows python
  WIN_SCRIPT_PATH=$(cygpath -w "$SCRIPT_DIR/firstaid.py" 2>/dev/null || wslpath -w "$SCRIPT_DIR/firstaid.py" 2>/dev/null || echo "$SCRIPT_DIR/firstaid.py")

  if $PYTHON_EXE "$WIN_SCRIPT_PATH" link 2>/dev/null; then
    return 0
  elif py "$WIN_SCRIPT_PATH" link 2>/dev/null; then
    return 0
  elif python3 "$SCRIPT_DIR/firstaid.py" link 2>/dev/null; then
    # We ignore errors from python3 in Bash as it might be a Linux binary failing to call Windows commands
    :
  fi

  # If all else fails, provide clear instructions
  echo ""
  echo "❌ Failed to create junction link from this environment."
  echo "This usually happens when running from WSL without Windows interop enabled,"
  echo "or when permissions are restricted."
  echo ""
  echo "💡 Please try one of the following from a Windows PowerShell or Command Prompt:"
  echo "   python \"$SCRIPT_DIR\firstaid.py\" link"
  echo "   OR"
  echo "   mklink /J \"$WIN_TARGET_DIR\" \"$WIN_SOURCE_DIR\""
  echo ""
  exit 1
}

case "$COMMAND" in
  sync)
    sync_playbook
    ;;
  remove)
    remove_playbook
    ;;
  link)
    link_playbook
    ;;
  *)
    echo "Usage: firstaid {sync|remove|link}"
    exit 1
    ;;
esac

echo ""
echo "🚑  FirstAid finished ⚕️"
echo "───────────────────────────────────────────────────────────────"