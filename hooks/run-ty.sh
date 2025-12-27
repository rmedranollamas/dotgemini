#!/usr/bin/env bash

# Read input
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only run on Python files
if [[ "$FILE_PATH" == *.py ]]; then
    # 1. Check (capture output)
    OUTPUT=$(ty check "$FILE_PATH" 2>&1)
    EXIT_CODE=$?

    # 2. If failed, return JSON to DENY/BLOCK
    if [ $EXIT_CODE -ne 0 ]; then
        jq -n \
           --arg out "$OUTPUT" \
           '{decision: "deny", hookSpecificOutput: {hookEventName: "AfterTool", additionalContext: ("Ty type check failed:\n" + $out) } }'
    fi
fi

