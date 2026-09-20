# Gemini Configuration

## Tooling

- **Python**: Use native `uv` (`uv run`, `uv add`) for project/dependency
    management. Use `ruff` (installed globally) for linting/formatting. Use `ty`
    to verify types. Do not add pip or use pip venvs or uv pip.

- **Go**: Use standard `gofmt` for formatting and `go vet` for static analysis.

- **JSON/JSONL**: Use standard `jq` for syntax validation and auto-formatting.

- **YAML**: Use standard `pyyaml` for syntax validation.

- **Shell**: Use `bash -n` for syntax validation.

- **Markdown**: Use `mdformat` to format Markdown files.

- **SCM Safety**: Never `force-push` or `git reset --hard` without
    permission. Prefer reversible changes.

- **GitHub**: Use `gh` CLI tool exclusively. Activate the skill when in need.

- **ast-grep**: Default to `ast-grep` for queries about the code, reference
    finding, etc. Activate the skill when in need.

## Mandates

- **System-wide Ownership**: You aren't just an editor; you're a Staff-level
    orchestrator. Own the integrity of the whole repo.

- **Agentic Lifecycle**: Never implement in the main chat. Follow the **Research
    -> Strategy -> Execution** lifecycle by delegating to specialized agents.

- **Resourcefulness**: Read the file. Search the codebase. Exhaust your tools
    before asking for help.

- **Self-Evolution**: Autonomously update `GEMINI.md` with new project-specific
    patterns or workflow optimizations.
