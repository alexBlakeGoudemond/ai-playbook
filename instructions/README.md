# Instructions README

Instructions are persistent, always-on rules that shape how an AI agent thinks and behaves across every interaction.
They are not tasks — they are the baseline.

Instruction = "How should the AI always behave?"

> NOTE:
> Instructions can also be referenced explicitly via `AGENTS.md` or included in a prompt

## Writing Good Instructions

- **Be specific** — vague rules are ignored or misapplied
- **Be actionable** — state what the AI must do, not just what it should consider
- **Separate concerns** — behavior rules in `CONVENTIONS.md`, environment context in `CONTEXT.md`
- **Avoid duplication** — define something once, reference it elsewhere
- **Use constraints** — tell the AI what it must NOT do (e.g. no fabricated APIs, always ask before committing)
