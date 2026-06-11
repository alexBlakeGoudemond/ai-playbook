# --------------------------------------------------------------------------------------------------------
# firstaid: bring markdown files from a source directory to a target directory, with sync and status features
# For fun, we named this little tool as `firstaid` because it assists in keeping your repository healthy and up-to-date!
# Usage: firstaid sync
# Usage: firstaid remove
# --------------------------------------------------------------------------------------------------------
import shutil
import sys
import os
import subprocess
from pathlib import Path

# Ensure UTF-8 output on Windows
if sys.platform == "win32":
    import io
    if hasattr(sys.stdout, 'buffer'):
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    if hasattr(sys.stderr, 'buffer'):
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

ALIAS_VERSION = "1.0.0"

TARGET_DIR = Path.cwd() / ".ai-playbook"
TARGET_STANDALONE_FILES_DESTINATION = TARGET_DIR.parent
SCRIPT_DIR = Path(__file__).parent.resolve()
AI_PLAYBOOK_SOURCE = SCRIPT_DIR.parent.parent
AI_PLAYBOOK_PATH = None

# Load .env file
env_file = SCRIPT_DIR / ".env"
if env_file.exists():
    # Try different encodings to handle files created by PowerShell (UTF-16) or others
    for encoding in ['utf-8', 'utf-16', 'utf-8-sig']:
        try:
            with open(env_file, "r", encoding=encoding) as f:
                for line in f:
                    if line.startswith("AI_PLAYBOOK_PATH="):
                        AI_PLAYBOOK_PATH = line.split("=", 1)[1].strip().strip('"').strip("'")
            break
        except (UnicodeDecodeError, LookupError):
            continue

PLAYBOOK_DIRS = [AI_PLAYBOOK_SOURCE / "instructions",
                 AI_PLAYBOOK_SOURCE / "prompts",
                 AI_PLAYBOOK_SOURCE / "workflows"]
STANDALONE_FILES = [AI_PLAYBOOK_SOURCE / "AGENTS.playbook.md"]


def print_start_banner():
    print(f"""
    🚑  FirstAid {ALIAS_VERSION} — AI Playbook ⚕️
    ───────────────────────────────────────────────────────────────
    """)


def print_end_banner():
    print(f"""
    🚑  FirstAid finished ⚕️
    ───────────────────────────────────────────────────────────────
    """)


def print_playbook_source():
    print(f"🔍 Source: {AI_PLAYBOOK_SOURCE}")


def print_target_directory():
    print(f"📁 Target: {TARGET_DIR}")


def verify_directories():
    # Mirror Bash's extra safety checks
    # Source exists and isn’t root
    if not AI_PLAYBOOK_SOURCE.exists() or AI_PLAYBOOK_SOURCE == AI_PLAYBOOK_SOURCE.root:
        print(f"❌ Invalid source directory")
        sys.exit(1)

        # Target isn’t root
    if TARGET_DIR == TARGET_DIR.root:
        print("❌ Invalid target directory")
        sys.exit(1)


def delete_target_directory(deleting_message, dont_exist_message):
    if TARGET_DIR.exists() or TARGET_DIR.is_symlink():
        if deleting_message:
            print(deleting_message)
        
        # On Windows, junctions are reported as directories but shutil.rmtree fails on them
        # if they are symlinks/junctions.
        if TARGET_DIR.is_dir() and not TARGET_DIR.is_symlink():
            try:
                shutil.rmtree(TARGET_DIR)
            except OSError:
                # Fallback for junctions if is_symlink() is False but it's still a junction
                if sys.platform == "win32":
                    try:
                        os.rmdir(TARGET_DIR)
                    except OSError:
                        TARGET_DIR.unlink()
                else:
                    raise
        else:
            # It's a symlink or a file
            try:
                if sys.platform == "win32" and TARGET_DIR.is_dir():
                    os.rmdir(TARGET_DIR)
                else:
                    TARGET_DIR.unlink()
            except OSError:
                TARGET_DIR.unlink()
    else:
        if dont_exist_message:
            print(dont_exist_message)


def delete_target_standalone_files():
    for standalone_file in STANDALONE_FILES:
        standalone_target_file = TARGET_STANDALONE_FILES_DESTINATION / standalone_file.name
        if not standalone_target_file.exists():
            print(f" ⚠️ Skipping missing file: {standalone_target_file}")
        else:
            print(f"  → Removing {standalone_target_file}")
            standalone_target_file.unlink()


def least_one_argument_is_provided():
    return len(sys.argv) > 1  # First argument is the script name


def get_first_argument():
    return sys.argv[1]


def print_usage():
    print("Usage: firstaid {sync|remove|link}")


def copy_playbook():
    for playbook_dir in PLAYBOOK_DIRS:
        if not playbook_dir.exists():
            print(f"  ⚠️ Skipping missing directory: {playbook_dir}")
            continue
        print(f"  → Copying {playbook_dir}")
        shutil.copytree(playbook_dir, TARGET_DIR / playbook_dir.name)


def copy_standalone_files():
    for standalone_file in STANDALONE_FILES:
        if not standalone_file.exists():
            print(f"  ⚠️ Skipping missing file: {standalone_file}")
            continue
        print(f"  → Copying {standalone_file}")
        shutil.copy2(standalone_file, TARGET_STANDALONE_FILES_DESTINATION / standalone_file.name)


def sync_playbook():
    print_start_banner()

    print_playbook_source()
    print_target_directory()
    verify_directories()
    delete_target_directory(f"🧹 Removing existing {TARGET_DIR}...", "")

    TARGET_DIR.mkdir()
    print("✒️  Copying selected AI Playbook components...")
    copy_playbook()
    copy_standalone_files()
    print("✅  Playbook synced successfully")

    print_end_banner()


def remove_playbook():
    print_start_banner()
    print("🧹 Removing AI Playbook...")
    delete_target_standalone_files()
    delete_target_directory(f"  → Removing {TARGET_DIR}",
                            f"  ⚠️ {TARGET_DIR} does not exist")
    print("✅ Remove complete")
    print_end_banner()


def link_playbook():
    if not AI_PLAYBOOK_PATH:
        print(f"❌ AI_PLAYBOOK_PATH is not defined. Please create a .env file in {SCRIPT_DIR} with AI_PLAYBOOK_PATH=<path>")
        sys.exit(1)

    print_start_banner()
    print(f"🔗 Linking to Global AI Playbook: {AI_PLAYBOOK_PATH}")
    print(f"📁 Target: {TARGET_DIR}")

    delete_target_directory(f"🧹 Removing existing {TARGET_DIR}...", "")

    print(f"  → Creating junction: {TARGET_DIR} -> {AI_PLAYBOOK_PATH}")
    try:
        # Use cmd /c mklink /J for Windows directory junction
        # We use absolute paths to be safe, and try both shell=True and shell=False
        target_abs = str(TARGET_DIR.absolute())
        source_abs = str(Path(AI_PLAYBOOK_PATH).absolute())
        
        # If we are on Windows, we should use cmd /c mklink
        if sys.platform == "win32":
            subprocess.run(f'cmd /c mklink /J "{target_abs}" "{source_abs}"', check=True, shell=True)
        else:
            # On non-windows (WSL python3), this will likely fail if it's linux python
            # but we can try to call cmd.exe if it's available in PATH
            try:
                subprocess.run(['cmd.exe', '/c', 'mklink', '/J', target_abs, source_abs], check=True)
            except (OSError, subprocess.CalledProcessError):
                # If cmd.exe failed, try ln -s as last resort (though the user wants junction)
                os.symlink(source_abs, target_abs, target_is_directory=True)
        
        print("✅ Playbook linked successfully")
    except subprocess.CalledProcessError:
        print("❌ Failed to create symlink. You might need to run this as Administrator or enable Developer Mode.")
        sys.exit(1)

    print_end_banner()


if __name__ == "__main__":
    if not least_one_argument_is_provided():
        print_usage()
        sys.exit(1)
    command = get_first_argument()

    match command:
        case 'sync':
            sync_playbook()
        case 'remove':
            remove_playbook()
        case 'link':
            link_playbook()
        case _:
            print_usage()
            sys.exit(1)
