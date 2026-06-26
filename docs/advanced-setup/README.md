# Advanced Setup

## AI Co-Author Attribution Hook

This folder contains a global `commit-msg` git hook that automatically credits AI tools as co-authors when they have
contributed 10% or more of the lines in a commit.

### How it works

The hook relies on [`git-ai`](https://git-ai.dev) to write line-level attribution data into `refs/notes/ai` as files are
edited. At commit time, the hook reads those notes to determine:

1. **Which sessions were AI-assisted** — sessions with an `agent_id` in the note JSON are treated as AI contributions
2. **What percentage of changed lines were AI-written** — calculated from the attribution ranges in the note
3. **Which tool to credit** — mapped from the `tool` field (e.g. `github-copilot-cli` → `GitHub Copilot`, `junie` →
   `JetBrains Junie`)

If the AI contribution is **≥ 10%**, a `Co-authored-by` trailer is appended to the commit message.

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
