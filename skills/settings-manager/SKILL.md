---
name: settings-manager
description: Specialized skill for managing, validating, and optimizing Gemini CLI `settings.json`. Uses the JSON schema as the source of truth for configuration.
updated: 2026-01-17
---

# Settings Manager Skill

Expert guidance for configuring the Gemini CLI. This skill prioritizes the JSON schema as the definitive source for available properties.

## Core Workflow

### 1. Schema-Based Validation
Always validate `settings.json` against the official schema after any manual edits.

```bash
# Define schema source
SCHEMA_URL="https://raw.githubusercontent.com/google-gemini/gemini-cli/main/schemas/settings.schema.json"

# Download to a temporary location
curl -s "$SCHEMA_URL" > /tmp/settings.schema.json

# Validate using check-jsonschema (Python/uvx)
uvx check-jsonschema --schemafile /tmp/settings.schema.json settings.json
```

# ... (existing sections)

### 3. Canonical Sorting
Sort `settings.json` keys to match the schema's order for better readability and alignment with documentation.

```python
import json
# Load schema and settings, then reconstruct settings:
schema_order = list(schema.get("properties", {}).keys())
sorted_settings = {k: settings[k] for k in schema_order if k in settings}
# Add remaining keys and save...
```

## Tool Policies
Tool permissions are managed via TOML files in the `policies/` directory. This replaces the legacy `tools.allowed` list in `settings.json`.

### Policy Structure (`policies/*.toml`)
...
```toml
[[rule]]
toolName = "run_shell_command"
decision = "allow"
priority = 100
commandPrefix = ["mdformat"]
```

## Common Hooks
- **run-ruff.sh:** Lints and formats Python files.
- **run-toml.sh:** Validates TOML syntax.
- **run-ty.sh:** Performs Python type checking.
- **run-mdformat.sh:** Formats Markdown files.

## Best Practices
# ... (existing sections)

## Common Configuration Blocks

### Experimental / Power User
Enable cutting-edge features and maximum agent autonomy.

```json
{
  "experimental": {
    "enableAgents": true,
    "extensionManagement": true,
    "extensionConfig": true,
    "extensionReloading": true,
    "jitContext": true,
    "skills": true,
    "plan": true,
    "codebaseInvestigatorSettings": {
      "enabled": true,
      "maxNumTurns": 30,
      "thinkingBudget": -1
    },
    "cliHelpAgentSettings": {
      "enabled": true
    }
  }
}
```

### UI & UX Optimization
Distraction-free "App Mode" with real-time status.

```json
{
  "ui": {
    "useAlternateBuffer": true,
    "showStatusInTitle": true,
    "dynamicWindowTitle": true,
    "useFullWidth": true,
    "showLineNumbers": true
  },
  "general": {
    "enablePromptCompletion": true
  }
}
```

## Troubleshooting

| Issue | Action |
|-------|--------|
| "Additional properties not allowed" | Property was likely renamed or moved. Check the schema's `$defs` or use `grep` on the schema. |
| Settings not applying | Ensure the JSON is valid (no trailing commas) and restart the CLI if the schema says `Requires restart: yes`. |

## References
- **Schema:** `https://raw.githubusercontent.com/google-gemini/gemini-cli/main/schemas/settings.schema.json`
- **Official Docs:** `https://geminicli.com/docs/get-started/configuration/`
