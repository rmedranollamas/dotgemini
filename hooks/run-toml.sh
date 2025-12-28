#!/usr/bin/env bash

# Best Practice: Robustness
# Check for dependencies

if ! command -v jq &> /dev/null;
    then
    echo "Error: jq is not installed. Skipping hook." >&2
    exit 0
fi

# Read input
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only run on TOML files
if [[ "$FILE_PATH" == *.toml ]]; then
    if [ ! -f "$FILE_PATH" ]; then
        exit 0
    fi

    # 1. Check syntax using python3 -c (since tomllib is available in Python 3.11+)
    # We use a subprocess to isolate the check
    OUTPUT=$(python3 -c "import tomllib; tomllib.load(open('$FILE_PATH', 'rb'))" 2>&1)
    EXIT_CODE=$?

    # 2. If failed, return JSON to DENY/BLOCK
    if [ $EXIT_CODE -ne 0 ]; then
        jq -n \
           --arg out "$OUTPUT" \
           '{decision: "deny", hookSpecificOutput: {hookEventName: "AfterTool", additionalContext: ("TOML validation failed:\n" + $out) } }'
    fi
fi