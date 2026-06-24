# Agents README

Agents are persistent, autonomous AI personas with a defined role, behavior, and toolset.
They operate independently to complete broader tasks, often across multiple steps.

Agent = "Who is doing the work, and how do they behave?"

> NOTE:
> Agents may be invoked using the `@` symbol in chat.
> May appear as separate from other personas: `chat`, `ask`, `plan`, etc

## Structure

A `.agent.md` file contains two parts:

**Frontmatter** – declares the metadata and available tools:

```yaml
---
description: Short description of what the agent does
tools: [ 'tool1', 'tool2', ... ]
---
```

**Body** – defines the agent's system prompt: its role, behavior rules, response style, and constraints.

## Writing a Good Agent

- **Define a clear role** – give the agent a specific job (e.g. code reviewer, architect, security auditor)
- **Set behavior rules** – describe how the agent should reason and prioritize
- **Set a response style** – concise vs. detailed, format preferences, tone
- **Set constraints** – what the agent must NOT do (e.g. no code modification, no invented behavior)
- **List focus areas** – topics the agent specializes in
