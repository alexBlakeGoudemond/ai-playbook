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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_PLAYBOOK_SOURCE="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Resolve the working directory: prefer the Git repo root so the command works
# correctly regardless of which subdirectory it is invoked from.
if git -C "$(pwd)" rev-parse --show-toplevel >/dev/null 2>&1; then
  WORK_DIR="$(git -C "$(pwd)" rev-parse --show-toplevel)"
else
  WORK_DIR="$(pwd)"
fi

TARGET_STANDALONE_FILES_DESTINATION="$WORK_DIR"

# Change into the repo root so all relative paths (TARGET_DIR etc.) resolve correctly
cd "$WORK_DIR"
echo "📂 Working directory: $WORK_DIR"

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

  # Convert current directory to a Windows path
  # pwd -W is the most reliable option in Git Bash (returns C:\... directly)
  if WIN_CWD=$(cd "$WORK_DIR" && pwd -W 2>/dev/null) && [ -n "$WIN_CWD" ]; then
    WIN_TARGET_DIR=$(echo "${WIN_CWD}\\${TARGET_DIR}" | sed 's|/|\\|g')
  elif command -v wslpath >/dev/null 2>&1; then
    WIN_TARGET_DIR=$(wslpath -w "${WORK_DIR}/${TARGET_DIR}" 2>/dev/null)
  elif command -v cygpath >/dev/null 2>&1; then
    WIN_TARGET_DIR=$(cygpath -w "${WORK_DIR}/${TARGET_DIR}" 2>/dev/null)
  else
    WIN_TARGET_DIR="$(echo "$WORK_DIR" | sed 's|^/\([a-zA-Z]\)/|\1:\\|')\\${TARGET_DIR}"
  fi

  # If AI_PLAYBOOK_PATH is already a Windows path (C:\... or C:/...), use it directly
  # This avoids cygpath/wslpath mangling an already-correct Windows path
  if echo "$AI_PLAYBOOK_PATH" | grep -qE '^[A-Za-z]:[/\\]'; then
    WIN_SOURCE_DIR=$(echo "$AI_PLAYBOOK_PATH" | sed 's|/|\\|g')
  elif command -v wslpath >/dev/null 2>&1; then
    WIN_SOURCE_DIR=$(wslpath -w "$AI_PLAYBOOK_PATH" 2>/dev/null)
  elif command -v cygpath >/dev/null 2>&1; then
    WIN_SOURCE_DIR=$(cygpath -w "$AI_PLAYBOOK_PATH" 2>/dev/null)
  else
    WIN_SOURCE_DIR=$(echo "$AI_PLAYBOOK_PATH" | sed 's|^/\([a-zA-Z]\)/|\1:\\|')
  fi

  WIN_TARGET_DIR=$(clean_win_path "$WIN_TARGET_DIR")
  WIN_SOURCE_DIR=$(clean_win_path "$WIN_SOURCE_DIR")

  # Sanity check: make sure the two paths are not identical
  if [ "$WIN_TARGET_DIR" = "$WIN_SOURCE_DIR" ]; then
    echo "❌ Path resolution error: target and source resolved to the same path."
    echo "   WIN_TARGET_DIR: $WIN_TARGET_DIR"
    echo "   WIN_SOURCE_DIR: $WIN_SOURCE_DIR"
    echo "   CWD (unix): $(pwd)"
    echo "   CWD (windows): ${WIN_CWD:-n/a}"
    echo "   AI_PLAYBOOK_PATH: $AI_PLAYBOOK_PATH"
    exit 1
  fi

  echo "🔗 Linking to Global AI Playbook: $AI_PLAYBOOK_PATH"
  echo "📁 Target: $TARGET_DIR"

  if [ -d "$TARGET_DIR" ] || [ -L "$TARGET_DIR" ]; then
    echo "  → Removing existing $TARGET_DIR..."
    rm -rf "$TARGET_DIR"
  fi

  echo "  → Creating junction: $WIN_TARGET_DIR -> $WIN_SOURCE_DIR"

  LINK_SUCCESS=false

  # -----------------------------------------------------------------
  # Method 1: Write a temp .ps1 file to C:\Windows\Temp and execute
  # with -File.  This completely sidesteps quoting/escaping problems
  # that occur when passing Windows paths through -Command in WSL.
  # -----------------------------------------------------------------
  WIN_TMPDIR="/mnt/c/Windows/Temp"
  TMPSCRIPT=""
  WIN_TMPSCRIPT=""
  if [ -d "$WIN_TMPDIR" ]; then
    TMPSCRIPT="$WIN_TMPDIR/firstaid_$$.ps1"
    WIN_TMPSCRIPT="C:\\Windows\\Temp\\firstaid_$$.ps1"
    printf "New-Item -ItemType Junction -Path '%s' -Target '%s' -ErrorAction Stop | Out-Null\n" \
      "$WIN_TARGET_DIR" "$WIN_SOURCE_DIR" > "$TMPSCRIPT" 2>/dev/null || TMPSCRIPT=""
  fi

  PS_PATHS=(
    "powershell.exe"
    "pwsh.exe"
    "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
    "/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
  )

  for ps_path in "${PS_PATHS[@]}"; do
    # Prefer -File (temp script) — no quoting issues
    if [ -n "$TMPSCRIPT" ] && [ -f "$TMPSCRIPT" ]; then
      if "$ps_path" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$WIN_TMPSCRIPT" >/dev/null 2>&1; then
        LINK_SUCCESS=true
        break
      fi
    fi
    # Fallback: -Command inline
    if "$ps_path" -NoProfile -NonInteractive -Command \
        "New-Item -ItemType Junction -Path '$WIN_TARGET_DIR' -Target '$WIN_SOURCE_DIR' -ErrorAction Stop | Out-Null" \
        >/dev/null 2>&1; then
      LINK_SUCCESS=true
      break
    fi
  done

  [ -n "$TMPSCRIPT" ] && rm -f "$TMPSCRIPT" 2>/dev/null

  if [ "$LINK_SUCCESS" = true ]; then
    echo "✅ Playbook linked successfully (via powershell)"
    return 0
  fi

  # -----------------------------------------------------------------
  # Method 2: cmd.exe mklink
  # -----------------------------------------------------------------
  CMD_PATHS=(
    "cmd.exe"
    "/mnt/c/Windows/System32/cmd.exe"
    "/c/Windows/System32/cmd.exe"
  )

  for cmd_path in "${CMD_PATHS[@]}"; do
    if "$cmd_path" /c "mklink /J \"$WIN_TARGET_DIR\" \"$WIN_SOURCE_DIR\"" >/dev/null 2>&1; then
      LINK_SUCCESS=true
      break
    fi
  done

  if [ "$LINK_SUCCESS" = true ]; then
    echo "✅ Playbook linked successfully (via cmd)"
    return 0
  fi

  # -----------------------------------------------------------------
  # Method 3: Unix symlink (works on WSL DrvFs with metadata enabled)
  # -----------------------------------------------------------------
  UNIX_SOURCE=""
  if command -v wslpath >/dev/null 2>&1; then
    UNIX_SOURCE=$(wslpath -u "$WIN_SOURCE_DIR" 2>/dev/null)
  fi
  if [ -n "$UNIX_SOURCE" ] && ln -s "$UNIX_SOURCE" "$TARGET_DIR" 2>/dev/null; then
    echo "✅ Playbook linked successfully (via symlink)"
    return 0
  fi

  # -----------------------------------------------------------------
  # All methods failed — provide manual instructions
  # -----------------------------------------------------------------
  echo ""
  echo "❌ Failed to create junction link from this environment."
  echo "This usually happens when running from WSL without Windows interop enabled,"
  echo "or when permissions are restricted."
  echo ""
  echo "💡 Please run one of the following manually:"
  echo "   # PowerShell:"
  echo "   New-Item -ItemType Junction -Path \"$WIN_TARGET_DIR\" -Target \"$WIN_SOURCE_DIR\""
  echo ""
  echo "   # Command Prompt:"
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