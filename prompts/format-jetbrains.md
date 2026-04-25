# Format Repository Content (JetBrains)

## Goal

Format and improve the structure, readability, and documentation of code and files in a JetBrains-based project (
IntelliJ).

## Instructions

- Follow language-specific conventions:
    - Java → Javadoc
    - Kotlin → KDoc
- Improve code readability without changing behavior
- Add or refine documentation where missing
- Ensure formatting aligns with standard IntelliJ defaults; prefer editorconfig settings over IDE settings 

## Documentation Rules

- Public classes and methods should have documentation, provided the documentation communicates beyond the method name
- Include:
    - Purpose
    - Parameters
    - Return values
- Keep comments concise and useful (avoid noise)

## Code Style

- Use clear naming
- Break down large functions
- Remove redundant or dead code where safe

## Input

{{content}}

## Output

- Cleaned and formatted code
- Improved documentation (Javadoc/KDoc where applicable)
- Brief summary of changes made