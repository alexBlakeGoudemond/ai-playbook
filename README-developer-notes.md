# Developer Notes

As mentioned in [README.md](README.md), the purpose of this AI Playbook is to have all the generic / reusable resources
available for any AI Tool. It is specifically designed to be flexible and usable by any AI tool.

Below are some notes for developers to explain what the Author(s) have learned from using this playbook.

## Isolating AI Tools between Work and Home

Suppose you are working for a client, and that client grants you access to an AI Tool, for example, GitHub Copilot.
On top of this, suppose you have personal projects that you work on outside work hours, and you ALSO have an account for
GitHub Copilot for your personal use. The question becomes: how do you ensure that the Work AI Tool is not used for
your personal projects and vice versa?

One potential solution, on the same laptop, is to use logically separated IDE environments. Jetbrains allows for IDE's
to have configuration environments defined such that one can have Work Instances and Personal Instances running at the
same time, as 2 separate clusters of IDEs on the taskbar.

Having an AI playbook for each is then tempting – 1 is tailored for the Client, the other for personal use

## Benefits of a Playbook

Common conventions, resources, skills etc can be drawn from a single place. It does not matter if you are using Copilot,
Claude, ChatGPT, etc - they can all have the same shared resources.

Having a playbook also prevents needing to reinvent the wheel by inserting into:

- `.agents/`
- `.claude/`
- `.github/`
- `~/.agents/`
- `~/.claude/`
- `~/.copilot/`

## Bests Practices

### Resource Conventions

Resources that the AI Tool can read may leverage YAML FrontMatter to encode metadata about the resource.
Examples of the metadata keys include:

| FrontMatter Key            | Description                                                                     |
|----------------------------|---------------------------------------------------------------------------------|
| `name`                     | Shorthand file name                                                             |
| `description`              | A brief description of the resource                                             |
| `disable-model-invocation` | Cannot be invoked by an AI Agent - must be invoked by a human                   |
| `adapted-by`               | The person who copied / drew inspiration from the author                        |
| `source`                   | If copied from an author - where is that resource located                       |
| `license`                  | The License associated with the Author's resource                               |
| `argument-hint`            | When is this resource best used?                                                |
| `workflow`                 | AI-Driven sequence of events                                                    |
| `skills`                   | AI-Driven resource used to extend what the AI can do                            |
| `guardrails`               | AI-Driven guidelines / rules to ensure consistency                              |
| `applies-when`             | Assists AI Tool to identify when a resource should be considered                |
| `requires`                 | Assists AI Tool to identify what needs to exist before the resource can be used |

### Delegation

This playbook has been designed to delegate where possible. In particular:

- The user can invoke a [prompt](prompts) – a repeatable question for the AI Tool to answer
- The Prompt delegates to a [workflow](workflows) – the sequence of steps for the AI Tool to follow
- The Workflow delegates to a [skill](skills) – additional considerations for the AI Tool to consider
- The Skill may delegate to a [guardrail](guardrails) – rules to consider to be consistent across requests

### Playbook Placement

There are currently a few strategies for using the playbook:

- (Local) Bring a copy into every project
    - Pros: can track with version control; can be edited and become unique to repo
    - Cons: it needs to be copied into every project and updated in every project when changes are made
- (Global) Have a single playbook loaded onto the machine, and link projects to it
    - Pros: only one playbook to maintain and update; can be used across all projects
    - Cons: cannot become unique to repo
- Combine the Global and Local strategies
    - Pros: Benefit from using the Global Playbook and then have more tailored Local Playbooks for each project
    - Cons: more work to maintain both Global and Local Playbooks; need to ensure consistency between them

> To achieve a mixture of Global and Local strategies, it is recommended to use a symlink to the Global Playbook and
> then dedicated directories for the additional local playbooks. This will appear as two directories in the IDE, and
> allow the AI tools to navigate to the resources, especially if the Global Playbook is in your `<users>` directory

### Playbook Usage

The AI Tools that have been tested so far have different settings and default behavior.

> For example, as of 2026-06-18, not all AI tools default to read AGENTS.md in every prompt (notable Jetbrains Junie)

A reliable method to ensure the playbook is being used is to write down the basic rules in one file (perhaps AGENTS.md),
and then for each prompt you explicitly state that the instructions in the AGENTS.md file should be used.

> NOTE:
> Transitive lookups do not appear to be supported by all AI Tools
> For example, this 'hopping' of rules, as of 2026-06-18, is not reliable:
> `AGENTS.md -> AGENTS.playbook.md -> .ai-playbook/INSTRUCTIONS.md / .ai-playbook/CONVENTIONS.md / ...`
> However a single redirect does appear to work:
> `AGENTS.md -> .ai-playbook/INSTRUCTIONS.md / .ai-playbook/CONVENTIONS.md / ...`

The contents of the playbook can then be referenced in the prompt, and expected behaviour defined there can be expected
to work.