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
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only run on Python files
if [[ "$FILE_PATH" == *.py ]]
then
    
    # Check if file exists
    if [ ! -f "$FILE_PATH" ]
    then
        # File might not exist yet if this is BeforeTool (but this is configured as AfterTool)
        # Or if path is bad.
        exit 0
    fi

    # Calculate hash before
    HASH_BEFORE=$(md5sum "$FILE_PATH" | awk '{print $1}')

    # 1. Format (silently)
    FORMAT_OUT=$(ruff format "$FILE_PATH" 2>&1)
    
    # 2. Check (capture output)
    CHECK_OUT=$(ruff check --fix "$FILE_PATH" 2>&1)
    EXIT_CODE=$?

    # Calculate hash after
    HASH_AFTER=$(md5sum "$FILE_PATH" | awk '{print $1}')

    # 3. If failed, return JSON to DENY/BLOCK
    if [ $EXIT_CODE -ne 0 ]
    then
        jq -n \
           --arg out "$CHECK_OUT" \
           '{decision: "deny", hookSpecificOutput: {hookEventName: "AfterTool", additionalContext: ("Ruff linting failed:\n" + $out)} }'
    elif [ "$HASH_BEFORE" != "$HASH_AFTER" ]
    then
        # File was modified (fixed/formatted)
        # Return a system message to inform the agent
        jq -n \
            --arg fmt "$FORMAT_OUT" \
            --arg chk "$CHECK_OUT" \
            '{systemMessage: ("Ruff auto-formatted/fixed " + $INPUT.tool_input.file_path + ". Output:\n" + $fmt + "\n" + $chk)}'
    fi
fi
