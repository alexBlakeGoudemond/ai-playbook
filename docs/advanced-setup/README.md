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

1. Copy `commit-msg` and `commit-msg.ps1` to your global git hooks directory:
   ```sh
   cp docs/advanced-setup/commit-msg ~/.git-hooks/commit-msg
   cp docs/advanced-setup/commit-msg.ps1 ~/.git-hooks/commit-msg.ps1
   chmod +x ~/.git-hooks/commit-msg
   ```
2. Set your global hooks path (if not already):
   ```sh
   git config --global core.hooksPath ~/.git-hooks
   ```
3. Ensure `git-ai` is installed and running so it writes `refs/notes/ai` during your editing sessions.
