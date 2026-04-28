# Add Documentation Workflow

## Goal

Add clear, consistent, and idiomatic documentation for a feature or module.

## Principles

- Documentation should live close to the code
- Only document where it adds value (avoid redundancy)

## Steps to Gather Context and Execute

1. Understand the feature
    - What does it do?
    - Why does it exist?
    - Who uses it?
2. Identify documentation targets
    - Public classes
    - Public methods/functions
    - Complex or non-obvious logic
3. Evaluate necessity
    - Is documentation missing?
    - Is existing documentation unclear or redundant?
    - Does naming already communicate intent sufficiently?
4. Prepare input
    - Collect relevant files or code snippets
    - Focus on areas identified in previous steps
5. Apply documentation
    - Execute [document-code.md](../prompts/document-code.md)
    - Provide prepared input as `{{content}}`
6. Review output
    - Is the documentation accurate?
    - Is it concise and non-redundant?
    - Does it follow project conventions?
7. Iterate if needed
    - Refine input or clarify intent
    - Re-run prompt

## Output

- Updated code with improved documentation, if needed
- Brief summary of changes made
