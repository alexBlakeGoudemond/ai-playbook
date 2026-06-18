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
  # Use tr -d '\r' to remove Windows line endings
  # Use sed to remove BOM if present (M-oM-;M-? is the UTF-8 BOM in cat -v)
  AI_PLAYBOOK_PATH=$(grep "^AI_PLAYBOOK_PATH=" "$SCRIPT_DIR/.env" | tr -d '\r' | sed 's/^\xEF\xBB\xBF//' | cut -d'=' -f2- | sed "s/^['\"]//;s/['\"]$//")
  
  # If the above fails because grep didn't match due to BOM at start of line
  if [ -z "$AI_PLAYBOOK_PATH" ]; then
    AI_PLAYBOOK_PATH=$(sed 's/^\xEF\xBB\xBF//' "$SCRIPT_DIR/.env" | tr -d '\r' | grep "^AI_PLAYBOOK_PATH=" | cut -d'=' -f2- | sed "s/^['\"]//;s/['\"]$//")
  fi
fi

PLAYBOOK_DIRS=("instructions" "prompts" "workflows" "agents" "skills")
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
  if [ -z "$AI_PLAYBOOK_PATH" ]; then
    echo "❌ AI_PLAYBOOK_PATH is not defined. Please create a .env file in $SCRIPT_DIR with AI_PLAYBOOK_PATH=<path>"
    exit 1
  fi

  # Use a helper function to fix path translation issues (weird UTF symbols)
  function clean_win_path() {
    # If the path contains Private Use Area characters used by WSL/Cygwin for illegal NTFS characters
    # (e.g. \uF03A for ':', \uF05C for '\'), we try to restore them.
    local path="$1"
    # Note: we use hex codes to match the UTF-8 bytes of these characters
    # \uF03A (:) is EF 80 BA
    # \uF05C (\) is EF 81 9C
    # \uF022 (") is EF 80 A2
    # \uF02A (*) is EF 80 AA
    # \uF03C (<) is EF 80 BC
    # \uF03E (>) is EF 80 BE
    # \uF03F (?) is EF 80 BF
    # \uF07C (|) is EF 81 BC
    path=$(echo "$path" | sed 's/\xEF\x80\xBA/:/g; s/\xEF\x81\x9C/\\/g; s/\xEF\x80\xA2/"/g; s/\xEF\x80\xAA/*/g; s/\xEF\x80\xBC/</g; s/\xEF\x80\xBE/>/g; s/\xEF\x80\xBF/?/g; s/\xEF\x81\xBC/|/g')
    echo "$path"
  }

  WIN_TARGET_DIR=$(cygpath -w "$(pwd)/$TARGET_DIR" 2>/dev/null || wslpath -w "$(pwd)/$TARGET_DIR" 2>/dev/null || echo "$(pwd | sed 's/^\/\([a-z]\)\//\1:\\/')\\$TARGET_DIR")
  WIN_SOURCE_DIR=$(cygpath -w "$AI_PLAYBOOK_PATH" 2>/dev/null || wslpath -w "$AI_PLAYBOOK_PATH" 2>/dev/null || echo "$AI_PLAYBOOK_PATH" | sed 's/^\/\([a-z]\)\//\1:\\/')

  WIN_TARGET_DIR=$(clean_win_path "$WIN_TARGET_DIR")
  WIN_SOURCE_DIR=$(clean_win_path "$WIN_SOURCE_DIR")

  echo "🔗 Linking to Global AI Playbook: $AI_PLAYBOOK_PATH"
  echo "📁 Target: $TARGET_DIR"

  if [ -d "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
    echo "  → Removing existing $TARGET_DIR..."
    rm -rf "$TARGET_DIR"
  fi

  echo "  → Creating junction: $WIN_TARGET_DIR -> $WIN_SOURCE_DIR"

  # Define potential cmd.exe paths
  CMD_PATHS=(
    "cmd.exe"
    "cmd"
    "/mnt/c/Windows/System32/cmd.exe"
    "/c/Windows/System32/cmd.exe"
    "C:/Windows/System32/cmd.exe"
  )

  LINK_SUCCESS=false
  for cmd_path in "${CMD_PATHS[@]}"; do
    if command -v "$cmd_path" >/dev/null 2>&1; then
      # Try without quotes first, then with quotes if it fails
      if "$cmd_path" /c "mklink /J $WIN_TARGET_DIR $WIN_SOURCE_DIR" >/dev/null 2>&1; then
        LINK_SUCCESS=true
        break
      elif "$cmd_path" /c "mklink /J \"$WIN_TARGET_DIR\" \"$WIN_SOURCE_DIR\"" >/dev/null 2>&1; then
        LINK_SUCCESS=true
        break
      fi
    fi
  done

  if [ "$LINK_SUCCESS" = true ]; then
    echo "✅ Playbook linked successfully"
    return 0
  fi

  # Fallback to Python bridge but ONLY for the mklink command to avoid double headers
  PYTHON_EXE=""
  if command -v python.exe >/dev/null 2>&1; then PYTHON_EXE="python.exe";
  elif command -v py.exe >/dev/null 2>&1; then PYTHON_EXE="py.exe";
  elif command -v python >/dev/null 2>&1; then PYTHON_EXE="python";
  elif command -v python3 >/dev/null 2>&1; then PYTHON_EXE="python3"; fi

  if [ -n "$PYTHON_EXE" ]; then
    # Try with raw strings and escaping
    if $PYTHON_EXE -c "import subprocess; subprocess.run(['cmd', '/c', 'mklink', '/J', r'$WIN_TARGET_DIR', r'$WIN_SOURCE_DIR'], check=True)" >/dev/null 2>&1; then
      echo "✅ Playbook linked successfully (via python bridge)"
      return 0
    elif $PYTHON_EXE -c "import subprocess; subprocess.run('cmd /c mklink /J \"$WIN_TARGET_DIR\" \"$WIN_SOURCE_DIR\"', check=True, shell=True)" >/dev/null 2>&1; then
      echo "✅ Playbook linked successfully (via python shell bridge)"
      return 0
    fi
  fi

  # If all else fails, provide clear instructions
  echo ""
  echo "❌ Failed to create junction link from this environment."
  echo "This usually happens when running from WSL without Windows interop enabled,"
  echo "or when permissions are restricted."
  echo ""
  echo "💡 Please try one of the following from a Windows PowerShell or Command Prompt:"
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