# .gemini - Personal Antigravity CLI (agy) Configuration

This repository contains my personal configurations, specialized agents, and automation hooks for the **Antigravity CLI (agy)**.

## 🏗️ Architecture

- **`config/`**: Global customizations and configuration files.
  - **`skills/`**: Expert guidance modules for the agent (e.g., `uv`, `ast-grep`, `ruff`, `ty`, `soul-manager`).
  - **`hooks/`**: Automated quality-gate validation scripts.
    - `run-gofmt.sh` & `run-govet.sh`: Go formatting and static analysis.
    - `run-ruff.sh` & `run-ty.sh`: Python linting, formatting, and type checking.
    - `run-json.sh`: JSON/JSONL validation and formatting.
    - `run-yaml.sh`: YAML syntax validation.
    - `run-toml.sh`: TOML syntax validation.
    - `run-shell.sh`: Shell script syntax validation.
    - `run-mdformat.sh`: Markdown formatting.
  - **`hooks.json`**: New-format validation hooks registration file mapped under `PreToolUse` (BeforeTool).
- **`antigravity-cli/`**: Active CLI session data, preferred preferences (\[settings.json\](file:///home/pi/.gemini/antigravity-cli/settings.json)), and keyboard mappings (\[keybindings.json\](file:///home/pi/.gemini/antigravity-cli/keybindings.json)).
- **`antigravity/`**: Electron desktop application data (including `webm_encoder`).

## 🚀 Workflow

This setup leverages native agent execution and lifecycle hooks:

1. **Orchestration**: The main agent handles high-level requests and delegates tasks to native built-in subagents (like `planner`, `implementer`, `verifier`) which have optimized prompts and model configs.
1. **Quality Gates**: Migrated hooks run on the host before any file modification tool executes (`PreToolUse`). If formatting or syntax validation fails, the write is intercepted and blocked to prevent corrupted code.

## 🛠️ Management

### Hook Logs

Hooks log to `config/hooks/hooks.log`. You can monitor execution in real-time:

```bash
tail -f ~/.gemini/config/hooks/hooks.log
```

## 📜 Core Files

- `GEMINI.md`: The "Source of Truth" for my engineering philosophy and tool usage.
- `SOUL.md`: Persona and core mandates of my assistant.
