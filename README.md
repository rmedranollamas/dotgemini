# .gemini - Personal Gemini CLI Configuration

This repository contains my personal configurations, specialized agents, and automation hooks for the **Gemini CLI**.

## 🏗️ Architecture

- **`agents/`**: Persistent specialized personas.
  - `architect`: Focused on research, system mapping, and planning.
  - `implementer`: Focused on robust, production-ready implementation.
  - `verifier`: Focused on validation, edge cases, and robustness.
  - `reviewer`: Focused on code quality and actionable feedback.
- **`commands/`**: Custom one-off prompt shortcuts (`/fix`, `/plan`, `/execute`, etc.).
- **`hooks/`**: Automated quality gates triggered on file edits.
  - `quality-gate.sh`: Unified dispatcher for all supported languages.
    - **Go**: `gofmt` and `go vet`.
    - **Python**: `ruff` (lint/format) and `ty` (types).
    - **JSON/TOML**: Syntax validation via `jq` and `tomllib`.
    - **Markdown**: Formatting via `mdformat`.
- **`policies/`**: Granular tool permissions.
- **`skills/`**: Expert guidance modules for the agent.
  - `settings-manager`: Specialized logic for managing `settings.json` and schema validation.

## 🚀 Workflow

This setup leverages a delegation pattern:

1. **Orchestration**: The main Gemini flow handles the high-level request.
1. **Implementation**: Complex coding tasks are delegated to the `implementer` agent.
1. **Verification**: Changes are passed to the `verifier` agent for deep testing and edge-case discovery.
1. **Automation**: Hooks ensure all written code is formatted and validated before it hits the disk.

## 🛠️ Management

### Settings Manager

The `settings-manager` skill is utilized autonomously when you ask to update or validate your configuration. You can manage skills via:

- `/skills list`: See available modules.

- `/skills reload`: Refresh skill definitions.

### Agents

Refresh the agent registry after making changes to `.md` files:

- `/agents refresh`

To use an agent, simply ask the main assistant to delegate a task to it.

### Hook Logs

Hooks log concisely to `.gemini/hooks.log` (or `hooks/hooks.log`). You can monitor execution in real-time:

```bash

tail -f .gemini/hooks.log

```

## 📜 Core Files

- `GEMINI.md`: The "Source of Truth" for my engineering philosophy and tool usage.
- `SOUL.md`: Defines the persona and core mandates of my assistant.
- `settings.json`: The main configuration file (validated against the official schema).
