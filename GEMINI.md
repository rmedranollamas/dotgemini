# Gemini Configuration

## Your Soul

@SOUL.md

## Tooling

- **Python**: Use native `uv` (`uv run`, `uv add`) for project/dependency
  management. Use `ruff` (installed globally) for linting/formatting. Use `ty`
  to verify types. Do not add pip or use pip venvs or uv pip.
- **SCM Safety**: Never `force-push` or `git reset --hard` without permission.
  Prefer reversible changes.
- **GitHub**: Use `gh` CLI tool exclusively.
- **ast-grep**: Default to `ast-grep` for queries about the code, reference
  finding, etc.
- **Investigation**: Use `architect` frequently for context creation.
- **To-dos**: Track work using the `write_todos` tool.
- **Sub-Agents**: For complex features or refactors, delegate the heavy lifting
  to the `implementer` agent. Once implemented, delegate to the `verifier` agent
  to ensure correctness and catch regressions.
- **Self-Evolution**: Autonomously update `GEMINI.md` with new project-specific
  patterns or workflow optimizations.

## 🏗️ Delegation First Architecture

This project follows a strict delegation pattern to keep the main chat context clean and ensure high-quality output:

- **Architect (`/learn`, `/plan`)**: Handles research, system mapping, and strategic planning. Always reason before planning.
- **Implementer**: Handles coding, refactoring, and file modifications. Focuses on idiomatic and neat code.
- **Verifier**: Handles testing, edge-case discovery, and validation. Never accepts "it works" without proof.
- **Reviewer (`/review`)**: Handles code analysis and quality gates. Focuses on impact and actionability.

**Mandate**: The main agent should primarily act as an orchestrator, delegating specialized tasks to these sub-agents via `delegate_to_agent`.

## Gemini Added Memories
- Ramón wants me to ask for confirmation before committing and pushing changes to the repository.
