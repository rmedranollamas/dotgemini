---
name: skill-author
description: Use when creating new skills, editing existing skills, or designing agentic capabilities and context files (GEMINI.md).
---

# Skill Authoring & Agent Architecture

## Overview

**Writing skills IS Test-Driven Development applied to process documentation.**

You write test cases (pressure scenarios with subagents), watch them fail
(baseline behavior), write the skill (documentation), watch tests pass (agents
comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you
don't know if the skill teaches the right thing.

## What is a Skill?

A **skill** is a reference guide for proven techniques, patterns, or tools. It
is a modular agent capability that follows the **progressive disclosure model**.

**Core Philosophy:** - **Bottom-up, not middle-out**: Analyze local workflows
and knowledge to encode them efficiently. Avoid "vibe-coding" skills for
imagined scenarios. - **The Model is the Customer**: Optimize for the
convenience and preference of the LLM ("desire paths"). - **Examples > Words**:
A single example is often worth a thousand descriptive tokens for a model.

## Directory Structure

```
skills/
skill-name/
    SKILL.md              # Main reference (required)
  scripts/              # Executable logic/tools
  references/           # Static data/heavy documentation
```

## SKILL.md Structure

**Frontmatter (YAML):** - `name`: Use lowercase-kebab-case (e.g., `processing-pdfs`,
`testing-code`). - `description`: Third-person. Describe ONLY
triggering conditions. Start with "Use when...". - **Single Line**: The
description MUST be a single line. Do NOT use folded block scalars (e.g., `>`).
**WHY**: Using block scalars will prevent the skill from being loaded. - **No
Comments**: Do NOT add any comments (e.g., `<!-- disableFinding(...) -->`)
inside the frontmatter (between the `---` lines). **WHY**: Comments in the
frontmatter will prevent the skill from being loaded. - **Line Length**: Ignore
line length warnings for the description line. Do NOT attempt to fix them
with wrapping or comments.- **CRITICAL**: Do NOT summarize the workflow in the
description (Gemini will skip reading the body).

**Body Sections:** - **Overview**: Core principle in 1-2 sentences. -
**Procedures**: Step-by-step instructions. - **Boundaries (ALWAYS/NEVER)**:
Clear constraints and safety rules. - **Quick Reference**: Tables or bullets for
common operations. Required for skills wrapping CLI tools. - **Examples**: 1-2
excellent, runnable examples.

## Technical Best Practices

### JSON by Default

Models process JSON more efficiently and reliably than Markdown tables,
especially for wide or complex data structures. Use JSON for structured
input/output in skills and scripts.

### Avoid Roundtrips

Move as much logic into code/scripts as possible. Don't tell the model to
perform a five-step sequence if a single script call in `scripts/` can execute
those steps and present the final result. Output tokens are expensive; tool
calls have error risk.

### CLI Optimizations

-   **Quiet Mode**: When using CLI binaries, always use silent/quiet flags (e.g., `npm test --silent` or `make run -s`) to save context tokens.
-   **JSON I/O**: Design internal tools to write and accept JSON.

## TDD for Skills (The Iron Law)

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

1.  **RED**: Run a pressure scenario with a subagent WITHOUT the skill. Document
    the exact rationalizations and failures.
2.  **GREEN**: Write the minimal skill addressing those specific violations. Run
    scenario WITH skill; agent must now comply.
3.  **REFACTOR**: Find new loopholes, add explicit counters, and re-verify.

## Structure & Polish

### Pave the Desire Paths

Observe the model's intuitive approach to a task. If it repeatedly makes the
same mistake (e.g., trying to use `grep -r`), don't just add a negative
instruction. Instead, adjust the environment or provide a tool that harnesses
that inclination (e.g., an MCP tool renamed to `grep`).

### Ordered Lists and Checklists

Instruction-following improves significantly with ordered lists and checklists.
Provide checklists that Gemini can copy into its response to track multi-step
progress (e.g., using `write_todos`).

### Polishing Skills

-   **Divide as Needed**: Split skills when the `SKILL.md` body exceeds ~500
    lines.
-   **Fewer, Comprehensive Skills**: Prefer fewer, richer skills over thousands
    of micro-skills. Aim for a "dozen core skills" per team.

## Creating Context Files (GEMINI.md / AGENTS.md)

Context files should be a **machine-readable playbook** defining: - **Why**:
Project purpose. - **What**: Tech stack, versions, and codebase map. - **How**:
One-liner commands for linting/testing single files by path.

### Gemini CLI Technical Tips

-   **Modular Imports**: Use `@file.md` to import documentation without bloating
    context.
-   **Hierarchical Order**: Global (`~/.gemini/`) -> Project Root ->
    Sub-directory.
-   **Chain-of-Thought**: Require Gemini to provide a plan before modifying
    code.
-   **Gemini 3 Prompting Guide**: Use [references/gemini-3-prompting-guide.md](references/gemini-3-prompting-guide.md)
    for advanced reasoning, planning, and instruction following best practices.

## Search Optimization (CSO)

-   **Keyword Coverage**: Include error messages, synonyms, and tool names.
-   **Token Efficiency**: Target <200 words for frequently-loaded skills, <500
    for others.
-   **Cross-Referencing**: Use exact skill names instead of paths.

## Red Flags (STOP and check for skills)

-   "This is just a simple question" (Questions are tasks)
-   "I'll just do this one thing first" (Check BEFORE doing anything)
-   "I know what that means" (Knowing the concept ≠ using the skill)

**Use flowcharts ONLY for:** - Non-obvious decision points - Process loops where
you might stop too early - "When to use A vs B" decisions

**Never use flowcharts for:** - Reference material → Tables, lists - Code
examples → Markdown blocks - Linear instructions → Numbered lists - Labels
without semantic meaning (step1, helper2)

## Code Examples

## Boundaries (ALWAYS/NEVER)

-   **ALWAYS** follow the RED-GREEN-REFACTOR cycle.

-   **NEVER** use folded block scalars (`>`) in descriptions.

-   **NEVER** add comments inside the frontmatter.

-   **NEVER** summarize the workflow in the description.

-   **WARNING**: `mdformat` can be destructive to fenced code blocks and complex
    lists; verify formatting manually if it fails.