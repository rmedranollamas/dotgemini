#!/usr/bin/env bash

# Best Practice: Robustness & Dependencies

if ! command -v jq &> /dev/null;
    then
    echo "Error: jq is not installed. Skipping hook." >&2
    exit 0
fi

if ! command -v ty &> /dev/null;
    then
    # Warning on stderr is good practice for missing optional tools
    echo "Warning: ty is not installed. Skipping type check." >&2
    exit 0
fi

# Read input
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "n/a"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
LOG_FILE="$GEMINI_PROJECT_DIR/hooks/hook.log"

# Only run on Python files
if [[ "$FILE_PATH" == *.py ]]; then
     if [ ! -f "$FILE_PATH" ]; then
        exit 0
    fi

    # 1. Check (capture output)
    OUTPUT=$(ty check "$FILE_PATH" 2>&1)
    EXIT_CODE=$?

    STATUS="SUCCESS"
    # 2. If failed, return JSON to DENY/BLOCK
    if [ $EXIT_CODE -ne 0 ]; then
        STATUS="FAILED"
        jq -n \
           --arg out "$OUTPUT" \
           '{decision: "deny", hookSpecificOutput: {hookEventName: "AfterTool", additionalContext: ("Ty type check failed:\n" + $out) } }'
    fi

    # Log execution
    if [[ "$GEMINI_DEBUG_HOOKS" != "false" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-ty.sh [Session: $SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
fi