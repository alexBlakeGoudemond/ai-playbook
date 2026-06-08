# --------------------------------------------------------------------------------------------------------
# firstaid: bring markdown files from a source directory to a target directory, with sync and status features
# For fun, we named this little tool as `firstaid` because it assists in keeping your repository healthy and up-to-date!
# Usage: firstaid sync
# Usage: firstaid remove
# --------------------------------------------------------------------------------------------------------
import shutil
import sys
from pathlib import Path

ALIAS_VERSION = "1.0.0"

TARGET_DIR = Path.cwd() / ".ai-playbook"
TARGET_STANDALONE_FILES_DESTINATION = TARGET_DIR.parent
SCRIPT_DIR = Path(__file__).parent.resolve()
AI_PLAYBOOK_SOURCE = SCRIPT_DIR.parent.parent
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
    if TARGET_DIR.exists():
        print(deleting_message)
        shutil.rmtree(TARGET_DIR)
    else:
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
    print("Usage: firstaid {sync|remove}")


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
        case _:
            print_usage()
            sys.exit(1)
