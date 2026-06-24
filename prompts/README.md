# Prompts README

Prompts are user-driven and outcome-oriented. They are short and concise.
A user can use a prompt to get a response.

Prompt = “What do you want?”

> NOTE:
> May be able to invoke at the beginning of a chat by using the slash `/`

## Structure

- Prompts are to be stored in the `prompts` folder
- Prompt files must have the `.prompt.md` extension

A `.prompt.md` file contains two parts:

**Frontmatter** – declares the metadata and available tools:

```yaml
name: PROMPT_NAME
description: Short description of what the prompt does
```

**Body** - defines the prompt itself

> It is recommended that the prompt name and the frontmatter name are the same
>
> The name of the prompt in the frontmatter appears to be the alias for the prompt when invoked in the chat with `/`
>
> The frontmatter `description` appears in the chat when the prompt is invoked via `/`