# Add Documentation Workflow

## Goal

Add clear, consistent, and idiomatic documentation for a feature or module.

## Principles

- Prefer language-native documentation:
    - Java → Javadoc
    - Kotlin → KDoc
    - Others → follow ecosystem standards
- Documentation should live close to the code where possible

## Steps

1. Understand the feature
    - What does it do?
    - Why does it exist?
    - Who uses it?
2. Identify documentation targets
    - Public classes
    - Public methods/functions
    - Complex logic sections
3. Confirm documentation is needed
    - Is it missing?
    - Is it redundant?
    - Does the current FileName and MethodName communicate the purpose enough?
4. Apply documentation
    - Use Javadoc/KDoc for code elements
    - Use Markdown for higher-level docs
5. Ensure coverage includes:
    - Purpose
    - Inputs (parameters)
    - Outputs (return values)
    - Side effects (if any)
6. Add examples where helpful
7. Validate
    - Is it understandable to someone new?
    - Is anything redundant or missing?

## Output Format

### Code-level

- Javadoc / KDoc on public APIs / Language specific docs

### Repo-level (if needed)

- Markdown:
    - Overview
    - Usage
    - Examples
    - Notes