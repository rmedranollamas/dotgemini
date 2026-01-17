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

### 2. Feature Discovery
When looking for new features or checking property types, query the schema directly.

```bash
# List all top-level categories
jq -r '.properties | keys[]' /tmp/settings.schema.json

# Find all boolean flags (potential features to enable)
grep -B 2 '"type": "boolean"' /tmp/settings.schema.json
```

## Best Practices

- **Schema as Truth:** If a property isn't in the schema, it's either deprecated or internal. Always check the schema before adding a setting.
- **Incremental Updates:** Change one section at a time (e.g., `ui`, then `experimental`) and validate in between.
- **Backup:** Keep a copy of your known-good `settings.json` before performing major refactors.

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
