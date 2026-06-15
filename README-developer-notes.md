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

TBD