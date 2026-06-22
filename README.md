# ai-playbook

Have all your AI configurations, conventions, workflows, defined prompts, etc. in one place. Then, any AI tool can use
it!

## Purpose

A collection of AI prompts, workflows, and configuration to improve development workflows.

## Structure

- `ai-playbook/instructions/` → General expectations for AI Agents
- `ai-playbook/prompts/` → Specific Unit of work to perform a single, well defined task
- `ai-playbook/workflows/` → Chunks of work that can be requested to be completed

## How to Use

This playbook has a script defined in this repository, which can be used to copy the playbook into any repository:
[ai-playbook-alignment.sh](./.custom-scripts/bin/ai-playbook-alignment.sh). To execute it, please follow the
instructions defined in [UsingCustomScripts.md](.custom-scripts/UsingCustomScripts.md).

What the script does is copy the relevant contents of the `ai-playbook` into the directory of choice.

Alternatively, you can create a junction (symlink) to a global AI Playbook directory using the `link` command:
1. Create a `.env` file in `.custom-scripts/bin/` with: `AI_PLAYBOOK_PATH=C:\path\to\your\ai-playbook`
2. Run `firstaid link` (or `ai-playbook-alignment.sh link`)

It is recommended to append the contents of the [AGENTS.playbook.md](AGENTS.playbook.md) into the `AGENTS.md` file in
the directory.

Once the `AGENTS.md` file contains the `pointers` to the additional topics, usage is as follows:

- Include AGENTS.md as part of the context of the query
- In the prompt – include a phrase like "Refer to AGENTS.md for more information"

Using the playbook has been tested and confirmed to work with the following LLMs:

- Jetbrains Junie
- Github Copilot (Sonnet 4.6)

To verify it is working – look for details outlined in the `.ai-playbook/instructions/` or include your own request.

> For example, [CONVENTIONS.md](./instructions/CONVENTIONS.md) mentions that before changes are made - a summary and
> proposal must be outlined, then the user must confirm the proposal BEFORE the agent changes anything.
> Alternatively, you can add personalities or conversation candy, such as "For the emperor!" (from Warhammer 40K)