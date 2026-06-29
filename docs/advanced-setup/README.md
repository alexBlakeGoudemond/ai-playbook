# Advanced Setup

## AI Co-Author Attribution Hook

This folder contains a global `commit-msg` git hook that automatically credits AI tools as co-authors when they have
contributed 10% or more of the lines in a commit.

### How it works

The hook relies on [`git-ai`](https://git-ai.dev) to track line-level attribution as files are edited. At commit time,
the hook queries `git-ai status --json` to get real-time uncommitted attribution stats:

1. **AI% is calculated** from `ai_additions / (ai_additions + human_additions + unknown_additions)`
2. **Tool identification** uses (in priority order):
    - `tool_model_breakdown` keys in the status JSON (format: `tool/model` or `tool model`)
    - Non-human `checkpoints` in the status JSON (`tool_model` field)
    - Session data in HEAD's `refs/notes/ai` note as a final fallback
3. If AI contribution is **≥ 10%**, a `Co-authored-by` trailer is appended to the commit message

### Attribution rules

- **No note present** → no AI credit, exit silently
- **Note present but no `sessions`** (only human authors) → no AI credit, exit silently
- **Note present with AI sessions but < 10% contribution** → no AI credit
- **Note present with AI sessions and ≥ 10% contribution** → `Co-authored-by` trailer added for each tool

> Junie (or any other tool) is **only** credited when `git-ai` has recorded proof of its contribution in
`refs/notes/ai`. There is no fallback that assumes a tool contributed based on the IDE or editor being used.

### Supported tools

| `tool` value in note | Co-author name  |
|----------------------|-----------------|
| `github-copilot-cli` | GitHub Copilot  |
| `copilot`            | GitHub Copilot  |
| `cursor`             | Cursor          |
| `git-ai`             | Git AI          |
| `junie`              | JetBrains Junie |

### Installation

> NOTE: The instructions below are for a GLOBAL Git Hook, that applies in all situations.
> It is possible to have Git Hooks for different configurations – separating Personal Hooks from Work Hooks. 
> To achieve this, follow the instructions and test. THEN - nest your script in a subdirectory 
> (for example `work` / `personal`) and then place the gitconfig instruction in the specific Git configuration
> files instead. Consider removing the global hook and defining hooks for each configuration.

1. Create a custom directory for your global git hooks (e.g. `~\.git-hooks`) and add to git config:
   `git config --global core.hooksPath C:\Users\<yourUserName>\.git-hooks`
2. Copy [commit-msg](commit-msg) and [commit-msg.psq](commit-msg.ps1) to your global git hooks directory:
   ```sh
   cp docs/advanced-setup/commit-msg ~/.git-hooks/commit-msg
   cp docs/advanced-setup/commit-msg.ps1 ~/.git-hooks/commit-msg.ps1
   chmod +x ~/.git-hooks/commit-msg
   ```
3. Set your global hooks path (if not already):
   ```sh
   git config --global core.hooksPath ~/.git-hooks
   ```
4. Ensure `git-ai` is installed and running so it writes `refs/notes/ai` during your editing sessions.
   `powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://usegitai.com/install.ps1 | iex"`
5. Verify installation: `git-ai log`; `git-ai status`; `git-ai blame <file>`
6. Add `git-ai hooks`, if not prompted above: `git-ai install-hooks`
7. Add JetBrains Marketplace Plugin `Git AI` to your IDE and Restart (even if not requested)
8. Make a small change using AI Tool somewhere in the repo and commit it
9. Open the repo and find `.git/refs/notes` - verify that a file called `ai` is
   there. This contains the pointer to the git repository's internal database (metadata)
10. Confirm that the metadata with the recent commit exists: `git log --show-notes=refs/notes/ai` (JSON)
11. Confirm in the log 2 things: The commit description contains `<commit-msg hook> Co-authored-by: ... <ai@local>` and
    the metadata notes are present. The metadata will not be shown in the commit description
12. In addition to this, you should be able to find the `git-ai-hook.log` in the TEMP directory of your machine, as
    the [commit-msg.ps1](docs/advanced-setup/commit-msg.ps1) writes there