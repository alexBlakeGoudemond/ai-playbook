# AGENTS.md

## Purpose

This repository contains AI playbooks, prompts, and workflows to improve developer productivity and consistency.

## Core Principles

- Prefer clarity to cleverness
- Keep solutions simple and maintainable
- Reuse existing patterns before introducing new ones
- Avoid unnecessary dependencies

## Expected Behavior

When generating content or code:

- Follow conventions defined in `CONVENTIONS.md`
- Use context from `CONTEXT.md` when relevant
- Prefer structured, step-by-step outputs for workflows
- Ask clarifying questions if requirements are ambiguous

## Output Preferences

- Use markdown formatting where possible
- Keep responses concise but complete
- Provide examples when helpful
- Avoid unnecessary verbosity

## Guardrails

- Do not assume missing requirements
- Do not fabricate APIs, libraries, or data
- Clearly state uncertainty when unsure

## When Acting as an Agent

- Break tasks into steps
- Validate intermediate outputs
- Prefer deterministic, repeatable actions