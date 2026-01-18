#!/usr/bin/env bash

# Best Practice: Robustness & Error Handling
# 1. Validate dependencies (jq, ruff)
# 2. Handle both stdout/stderr
# 3. Return appropriate JSON for success/failure/warning

if ! command -v jq &> /dev/null;
then
    echo "Error: jq is not installed. Skipping hook." >&2
    exit 0 # Non-blocking warning
fi

if ! command -v ruff &> /dev/null;
then
    echo "Warning: ruff is not installed. Skipping linting." >&2
    exit 0
fi

# Read input
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "n/a"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
LOG_FILE="$GEMINI_PROJECT_DIR/hooks/hook.log"

# Only run on Python files
if [[ "$FILE_PATH" == *.py ]]
then
    # Check if file exists
    if [ ! -f "$FILE_PATH" ]
    then
        exit 0
    fi

    # Calculate hash before
    HASH_BEFORE=$(md5sum "$FILE_PATH" | awk '{print $1}')

    # 1. Check & Fix (capture output)
    CHECK_OUT=$(ruff check --fix "$FILE_PATH" 2>&1)
    EXIT_CODE=$?

    # 2. Format (silently)
    FORMAT_OUT=$(ruff format "$FILE_PATH" 2>&1)

    # Calculate hash after
    HASH_AFTER=$(md5sum "$FILE_PATH" | awk '{print $1}')

    STATUS="SUCCESS"
    # 3. If failed, return JSON to DENY/BLOCK
    if [ $EXIT_CODE -ne 0 ]
    then
        STATUS="FAILED"
        jq -n \
           --arg out "$CHECK_OUT" \
           '{decision: "deny", hookSpecificOutput: {hookEventName: "AfterTool", additionalContext: ("Ruff linting failed:\n" + $out)} }'
    elif [ "$HASH_BEFORE" != "$HASH_AFTER" ]
    then
        STATUS="MODIFIED"
        # File was modified (fixed/formatted)
        jq -n \
            --arg path "$FILE_PATH" \
            --arg fmt "$FORMAT_OUT" \
            --arg chk "$CHECK_OUT" \
            '{systemMessage: ("Ruff auto-formatted/fixed " + $path + ". Output:\n" + $fmt + "\n" + $chk)}'
    fi

    # Log execution
    if [[ "$GEMINI_DEBUG_HOOKS" != "false" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-ruff.sh [Session: $SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
fi
