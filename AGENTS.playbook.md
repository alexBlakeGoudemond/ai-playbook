# AI Development Guidelines

<!-- 
    FOR THE HUMANS -------------------------------------------------------------
        Delegations like this do not appear to work with all agents
        ```
        AGENTS.md
            -> AGENTS.playbook.md
                -> .ai-playbook
        ```
        However, delegations like this do seem to work, provided 
         the AGENTS.md file is part of the context and an instruction like 
         "Refer to AGENTS.md for more information" is included in the prompt
        ```
        AGENTS.md
            -> .ai-playbook
        ```
        Consider placing the contents of this file in the AGENTS.md file 
         and removing this file or adding this file to gitignore
    FOR THE HUMANS -------------------------------------------------------------
-->

This repository uses a centralized AI playbook.

Primary source of truth:

- .ai-playbook/instructions/AGENTS.md
- .ai-playbook/instructions/CONVENTIONS.md
- .ai-playbook/instructions/CONTEXT.md

Follow these rules when generating or modifying code:

- Prefer patterns defined in the AI playbook
- Maintain consistency with existing architecture
- Use repository conventions over generic suggestions
