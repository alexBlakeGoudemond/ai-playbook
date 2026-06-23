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
import argparse
from pathlib import Path

# Ensure UTF-8 output on Windows
if sys.platform == "win32":
    import io
    if hasattr(sys.stdout, 'buffer'):
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    if hasattr(sys.stderr, 'buffer'):
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

ALIAS_VERSION = "1.0.0"

SCRIPT_DIR = Path(__file__).parent.resolve()
AI_PLAYBOOK_SOURCE = SCRIPT_DIR.parent.parent


def _get_work_dir() -> Path:
    """Return the git repo root, falling back to cwd."""
    try:
        result = subprocess.run(
            ['git', 'rev-parse', '--show-toplevel'],
            capture_output=True, text=True, check=True,
        )
        return Path(result.stdout.strip())
    except (subprocess.CalledProcessError, FileNotFoundError):
        return Path.cwd()


WORK_DIR = _get_work_dir()
# TARGET_DIR and TARGET_STANDALONE_FILES_DESTINATION are set after arg-parsing below.
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
                 AI_PLAYBOOK_SOURCE / "agents",
                 AI_PLAYBOOK_SOURCE / "skills",
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


def _is_wsl() -> bool:
    """Return True when running inside Windows Subsystem for Linux."""
    try:
        with open('/proc/version', 'r') as f:
            return 'microsoft' in f.read().lower()
    except OSError:
        return False


def _win_path_to_wsl(win_path: str) -> str:
    """Convert a Windows-style path (C:\\foo\\bar) to a WSL path (/mnt/c/foo/bar)."""
    try:
        result = subprocess.run(
            ['wslpath', win_path],
            capture_output=True, text=True, check=True,
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        import re
        m = re.match(r'^([A-Za-z]):[/\\](.*)', win_path)
        if m:
            drive = m.group(1).lower()
            rest = m.group(2).replace('\\', '/')
            return f'/mnt/{drive}/{rest}'
        return win_path


def link_playbook():
    if not AI_PLAYBOOK_PATH:
        print(f"❌ AI_PLAYBOOK_PATH is not defined. Please create a .env file in {SCRIPT_DIR} with AI_PLAYBOOK_PATH=<path>")
        sys.exit(1)

    print_start_banner()
    print(f"📂 Working directory: {WORK_DIR}")
    print(f"🔗 Linking to Global AI Playbook: {AI_PLAYBOOK_PATH}")
    print(f"📁 Target: {TARGET_DIR}")

    delete_target_directory(f"  → Removing existing {TARGET_DIR}...", "")

    target_abs = str(TARGET_DIR.absolute())
    # AI_PLAYBOOK_PATH is already a Windows path from .env; normalise slashes
    source_abs = str(Path(AI_PLAYBOOK_PATH))

    # When running in WSL, convert Windows paths to WSL-compatible paths so that
    # the Unix symlink (Method 3 fallback) resolves correctly inside WSL.
    running_in_wsl = _is_wsl()
    if running_in_wsl:
        import re
        if re.match(r'^[A-Za-z]:[/\\]', source_abs):
            source_abs = _win_path_to_wsl(source_abs)
        if re.match(r'^[A-Za-z]:[/\\]', target_abs):
            target_abs = _win_path_to_wsl(target_abs)

    link_type = "symlink" if running_in_wsl or sys.platform != "win32" else "junction"
    print(f"  → Creating {link_type}: {target_abs} -> {source_abs}")

    linked = False

    # ------------------------------------------------------------------
    # Method 1: PowerShell New-Item -ItemType Junction via temp .ps1 file
    # Writing to a temp file avoids all quoting / backslash-escaping issues
    # when passing Windows paths through subprocess arguments.
    # ------------------------------------------------------------------
    tmp_ps1 = None
    try:
        import tempfile
        tmp_dir = r'C:\Windows\Temp' if sys.platform == "win32" else None
        ps_cmd = f"New-Item -ItemType Junction -Path '{target_abs}' -Target '{source_abs}' -ErrorAction Stop | Out-Null\n"
        with tempfile.NamedTemporaryFile(mode='w', suffix='.ps1',
                                        dir=tmp_dir, delete=False) as f:
            f.write(ps_cmd)
            tmp_ps1 = f.name

        for ps_exe in ['powershell.exe', 'pwsh.exe']:
            try:
                subprocess.run(
                    [ps_exe, '-NoProfile', '-NonInteractive',
                     '-ExecutionPolicy', 'Bypass', '-File', tmp_ps1],
                    check=True, capture_output=True,
                )
                linked = True
                break
            except (subprocess.CalledProcessError, FileNotFoundError):
                continue
    except Exception:
        pass
    finally:
        if tmp_ps1:
            try:
                os.unlink(tmp_ps1)
            except OSError:
                pass

    # ------------------------------------------------------------------
    # Method 2: cmd.exe mklink /J
    # ------------------------------------------------------------------
    if not linked:
        for cmd_exe in (['cmd.exe'] if sys.platform == "win32" else
                        ['cmd.exe', '/mnt/c/Windows/System32/cmd.exe']):
            try:
                subprocess.run(
                    f'"{cmd_exe}" /c mklink /J "{target_abs}" "{source_abs}"',
                    check=True, shell=True, capture_output=True,
                )
                linked = True
                break
            except (subprocess.CalledProcessError, FileNotFoundError):
                continue

    # ------------------------------------------------------------------
    # Method 3: Unix symlink (WSL / Git Bash with DrvFs metadata)
    # ------------------------------------------------------------------
    if not linked:
        try:
            os.symlink(source_abs, target_abs, target_is_directory=True)
            linked = True
        except OSError:
            pass

    if not linked:
        print("❌ Failed to create junction link.")
        print("💡 Please run one of the following manually:")
        print(f'   # PowerShell:')
        print(f'   New-Item -ItemType Junction -Path "{target_abs}" -Target "{source_abs}"')
        print(f'   # Command Prompt:')
        print(f'   mklink /J "{target_abs}" "{source_abs}"')
        sys.exit(1)

    print(f"✅ Playbook linked successfully (via {link_type})")
    print_end_banner()


def print_usage():


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog='firstaid',
        description='AI Playbook alignment tool',
    )
    subparsers = parser.add_subparsers(dest='command', metavar='{sync|remove|link}')

    _name_help = 'Target directory name (default: .ai-playbook)'

    p_sync = subparsers.add_parser('sync', help='Copy playbook into the repo')
    p_sync.add_argument('-n', '--name', default='.ai-playbook', metavar='DIR', help=_name_help)

    p_remove = subparsers.add_parser('remove', help='Remove playbook from the repo')
    p_remove.add_argument('-n', '--name', default='.ai-playbook', metavar='DIR', help=_name_help)

    p_link = subparsers.add_parser('link', help='Create a junction to the global playbook')
    p_link.add_argument('-n', '--name', default='.ai-playbook', metavar='DIR', help=_name_help)

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    # Set globals that depend on the chosen target name
    TARGET_DIR = WORK_DIR / args.name
    TARGET_STANDALONE_FILES_DESTINATION = WORK_DIR

    match args.command:
        case 'sync':
            sync_playbook()
        case 'remove':
            remove_playbook()
        case 'link':
            link_playbook()
        case _:
            parser.print_help()
            sys.exit(1)
