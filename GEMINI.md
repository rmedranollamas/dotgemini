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
- **Investigation**: Use `codebase_investigator` frequently for context creation.
- **To-dos**: Track work using the `write_todos` tool.
- **Self-Evolution**: Autonomously update `GEMINI.md` with new project-specific
  patterns or workflow optimizations.

