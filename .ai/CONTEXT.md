# CONTEXT.md

## Development Environment

- Primary IDE: IntelliJ
- Shell: Bash / PowerShell
- Version Control: Git

## Executing Workflows

- Feature development via branch naming conventions
- Pull request-driven development
- Script-driven automation (see dev-scripts repo)
- Additional Workflows are defined in `/workflows/`

## Common Prompts

- Reusable instructions have been prepared and placed in the `/prompts/` folder
- The user or workflows may invoke prompts
- Prompts should be executed with only the relevant scoped input
- Avoid passing entire files if only small sections need documentation

## Naming Conventions

- Branches include JIRA ticket when available
- Kebab-case for branch names
- Descriptive naming is preferred over short names

## Tooling

- GitHub Copilot used for assistance
- Custom scripts for repetitive workflows

## Philosophy

- Automate repetitive tasks
- Standardize common workflows
- Treat AI as a collaborator, not an authority