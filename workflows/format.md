# Format Repository Content Workflow

## Goal

Format repository content to improve readability and maintainability.

## Principles

- Prefer clarity and readability over cleverness
- Do not change behavior unless explicitly intended
- Keep formatting and structural improvements deterministic and repeatable
- Use language-native conventions (e.g., CamelCase, snake_case) where relevant
- Avoid introducing unnecessary abstractions or complexity

## Steps to Gather Context and Execute

1. Identify the scope of formatting
    - Entire file
    - Specific module
    - Selected snippet
    - whole codebase
2. Understand language context, where needed
3. Assess the current state
    - Is the structure inconsistent?
    - Are naming conventions unclear?
    - Is documentation missing or noisy?
    - Are there obvious readability issues?
4. Prepare input
    - Extract only relevant code or files
    - Avoid including unrelated context unless necessary
5. Apply formatting and structural improvements
    - Use prompt: [format-code-jetbrains.md](../prompts/format-code-jetbrains.md) 
    - Provide prepared input as `{{content}}`

## Output

- Cleaned, formatted code with the desired structure and readability
- Brief summary of changes made
