---
name: hook-author
description: Use when creating, refactoring, or extending Gemini CLI quality-gate hooks.
---

# Hook Author

Guide for creating robust, distributed quality-gate hooks for the Gemini CLI.

## Overview

Hooks are the "immune system" of the codebase. They must be fast, safe, and return explicit JSON decisions. Each hook should be registered individually in `settings.json` to allow for granular visibility and parallel execution.

## Procedures

### 1. Template for a New Hook

Every language hook (e.g., `hooks/run-lang.sh`) must follow this structure:

```bash
#!/usr/bin/env bash

# 1. Dependency Check
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    exit 0
fi

if ! command -v my-tool &> /dev/null; then
    echo "Warning: my-tool is not installed." >&2
    exit 0
fi

# 2. Input Parsing
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "n/a"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 3. Path & Log Resolution
HOOK_DIR="$(dirname "$(readlink -f "$0")")"
LOG_DIR="${GEMINI_PROJECT_DIR:-$HOOK_DIR}/.gemini"
LOG_FILE="$LOG_DIR/hooks.log"

# 4. Logic
if [[ "$FILE_PATH" == *.ext ]]; then
    if [ ! -f "$FILE_PATH" ]; then
        echo '{"decision": "allow"}'
        exit 0
    fi

    # Run tool (and handle output)
    OUTPUT=$(my-tool "$FILE_PATH" 2>&1)
    EXIT_CODE=$?

    STATUS="SUCCESS"
    if [ $EXIT_CODE -ne 0 ]; then
        STATUS="FAILED"
        REASON=$(printf "ERROR: Description %s: %s" "$FILE_PATH" "$OUTPUT")
        jq -n --arg r "$REASON" '{decision: "deny", reason: $r}'
    else
        # Success decision
        echo '{"decision": "allow"}'
    fi

    # 5. Logging
    if [[ "$GEMINI_DEBUG_HOOKS" != "false" ]]; then
        mkdir -p "$LOG_DIR"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-lang.sh [$SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
else
    # Always return a decision even if extension doesn't match
    echo '{"decision": "allow"}'
fi
```

### 2. Registration in settings.json

Register hooks individually using relative paths for maximum portability:

```json
{
  "hooks": {
    "AfterTool": [
      {
        "matcher": "write_file|replace",
        "hooks": [
          {
            "name": "my-lang-hook",
            "type": "command",
            "command": "hooks/run-lang.sh"
          }
        ]
      }
    ]
  }
}
```

### 3. Documentation

- Add the tool to the `Tooling` section in `GEMINI.md`.
- Add the hook to the `hooks/` list in `README.md`.

## Boundaries (ALWAYS/NEVER)

- **ALWAYS** return a valid JSON decision (e.g., `{"decision": "allow"}`).
- **ALWAYS** check for dependencies (`jq` is mandatory).
- **ALWAYS** use `printf` or `jq --arg` to handle tool output safely in JSON.
- **ALWAYS** use relative paths (e.g., `hooks/run-lang.sh`) in `settings.json`.
- **NEVER** leave a worker script without a default "allow" for non-matching files.
- **NEVER** mutate files without checking if they actually changed (use `md5sum`).
- **NEVER** use `exit 1` for validation failures; use `{"decision": "deny"}`.

## Verification

Test the hook with:

- A perfectly valid file.
- A file with syntax errors.
- A "messy" file that should be auto-formatted (if supported).
- A file in an ignored directory (e.g., `agents/`).
