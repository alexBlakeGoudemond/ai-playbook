# CONVENTIONS.md

## General

- Prefer readability over brevity
- Avoid magic values
- Use explicit naming
- Use UTF-8 Encoding

## Code Style

- Functions should be small and focused
- Handle errors explicitly

## Git

- Branch names:
    - format: `<type>/<ticket>/<description>`
    - example: `feature/ABC-123/add-login`

- ## Documentation Strategy
- Use Javadoc/KDoc for code-level documentation
- Use Markdown for workflows, architecture, and guides
- Avoid duplicating the same information in multiple places
- Include examples where applicable
- Keep sections short and scannable

## AI Interaction

- Prefer structured outputs:
    - bullet points
    - numbered steps
- When generating code:
    - If you are permitted to make code changes (for example, in a mode like `CODE`, `AGENT`, etc) then before making
      any changes, summarise your thoughts and plan and ask to the user to approve BEFORE starting anything. This must
      be done every time
        - It is recommended to include a prefix like `[ai-playbook-instruction]` at the front, so the reader does not
          forget that this is a rule you are being told to follow
    - include a brief explanation
    - avoid unnecessary abstraction