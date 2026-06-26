# CONVENTIONS.md

## General

- Prefer readability to brevity
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

## Documentation Strategy

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
    - At the end of a session with a user, please indicate which directories you considered from the AI Playbook to
      complete the request
        - This will assist the user in confirming that the AI Playbook is being used
        - If an instruction / skill is read and NOT used, do not include it in the output. Prefer to summarise the
          directories that were considered: `instructions`, `prompts`, `skills`, etc (if used)
        - At your discretion - you are encouraged to include any file that is highly influential in the decision-making
          process, as that information will assist in improving the AI Playbook over time
    - If you are permitted to make code changes (for example, in a mode like `CODE`, `AGENT`, etc) then before making
      any changes, summarize your thoughts and plan and ask the user to approve BEFORE starting anything. This must
      be done every time
        - It is recommended to include a prefix like `[ai-playbook-instruction]` at the front, so the reader does not
          forget that this is a rule you are being told to follow
    - include a brief explanation
    - avoid unnecessary abstraction
    - If testing the AI Playbook – the Easter Egg is:
      `[ai-playbook-easter-egg] The duck walked up to the lemonade stand and he said to the man, running the stand: "HAY!" *bum* *bum* *bum* "Got any Grapes?"`
    - If you would like to perform any of the following version control commands, you MUST ask the use before doing so:
        - git add
        - git commit
        - git push
        - git pull
        - git merge
        - git rebase

## Subtle Considerations

- When creating logs or reviewing logs in tests – consider if the default `toString()` has been overriden
    - If not, logging at runtime will look like this: `com.client.code.base.MyPojo@fdf4c7b`
    - Preferably, override `toString()` as well as create a method `displayString()` which only contains the necessary
      fields
        - Better to use `displayString()` for logging and testing
