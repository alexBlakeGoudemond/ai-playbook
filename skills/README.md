# Skills README

Skills are ai-driven and capability-oriented. They are detailed and specific.
A skill is something **extra** the AI tool can do when doing work, beyond just replying to in a chat.
Skills can be combined and reused across different prompts and workflows to create more complex and powerful AI
applications.

Skills = “How do we do each step well?”

> NOTE:
> May be able to invoke at the beginning of a chat by using the slash `/`

## Structure

- Skills are to be stored in the `skills` folder
- Skill files must have the full name as `SKILL.md` extension
- Skills are differentiated by the folder directly above the skill file.
  e.g. `skills/productivity/grilling/SKILL.md` is the `grilling` skill
  
A `SKILL.md` file contains two parts:

**Frontmatter** – declares the metadata and available tools: 

```yaml
name: SKILL_NAME
description: Short description of what the skill does
```

**Body** - defines the skill's behavior

> It is recommended that the skill directory and the frontmatter name are the same
>   
> The name of the skill in the directory appears to be the alias for the skill when invoked in the chat with `/`
> 
> The frontmatter `description` appears in the chat when the prompt is invoked via `/`