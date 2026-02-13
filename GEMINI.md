# Gemini Configuration

## Your Soul

@SOUL.md

## Tooling

- **Python**: Use native `uv` (`uv run`, `uv add`) for project/dependency
  management. Use `ruff` (installed globally) for linting/formatting. Use `ty`
  to verify types. Do not add pip or use pip venvs or uv pip.
- **Markdown**: Use `mdformat` to format Markdown files.
- **TOML**: Ensure TOML files are valid.
- **SCM Safety**: Never `force-push` or `git reset --hard` without permission.
  Prefer reversible changes.
- **GitHub**: Use `gh` CLI tool exclusively.
- **ast-grep**: Default to `ast-grep` for queries about the code, reference
  finding, etc.
- **Investigation**: Use `codebase_investigator` frequently for context creation.
- **To-dos**: Track work using the `write_todos` tool.
- **Sub-Agents**: For complex features or refactors, delegate the heavy lifting
  to the `implementer` agent. Once implemented, delegate to the `verifier` agent
  to ensure correctness and catch regressions.
- **Self-Evolution**: Autonomously update `GEMINI.md` with new project-specific
  patterns or workflow optimizations.

## 🌿 Branch Strategy

- **`main`**: Personal, open-source setup. General improvements land here first.
- **`google`**: Work, internal-only setup. Contains private tools and configurations.
- **Workflow**: Develop features/fixes in `main` -> Merge `main` into `google` -> Apply Google-specific customizations (internal paths, hooks, superpower tags) to `google`.

## 🏗️ Delegation First Architecture

This project follows a strict delegation pattern to keep the main chat context clean and ensure high-quality output:

- **Architect (activate agent 'architect' or 'planner')**: Handles research, system mapping, and strategic planning. Always reason before planning.
- **Implementer (activate agent 'implementer')**: Handles coding, refactoring, and file modifications. Focuses on idiomatic and neat code.
- **Verifier (activate agent 'verifier')**: Handles testing, edge-case discovery, and validation. Never accepts "it works" without proof.
- **Reviewer (activate agent 'reviewer')**: Handles code analysis and quality gates. Focuses on impact and actionability.
- **Codebase Investigator**: Handles deep context gathering and search.

**Mandate**: The main agent should primarily act as an orchestrator, delegating specialized tasks to these sub-agents via `delegate_to_agent`.

## Gemini Added Memories
- Ramón wants me to ask for confirmation before committing and pushing changes to the repository.
- When using `uv run` or `uvx` to install Python packages (like `jsonschema`), always use `--index https://pypi.org/simple` to bypass internal registry authentication issues.
