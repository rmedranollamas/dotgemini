#!/usr/bin/env bash

if ! command -v jq &> /dev/null;
    then
    echo "Error: jq is not installed." >&2
    exit 0
fi

if ! command -v ruff &> /dev/null;
    then
    echo "Warning: ruff is not installed." >&2
    exit 0
fi

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "n/a"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Reliable log directory resolution
HOOK_DIR="$(dirname \"$(readlink -f \"$0\")\")"
if [ -n "$GEMINI_PROJECT_DIR" ]; then
    LOG_DIR="$GEMINI_PROJECT_DIR/.gemini"
else
    LOG_DIR="$HOOK_DIR"
fi
LOG_FILE="$LOG_DIR/hooks.log"

if [[ "$FILE_PATH" == *.py ]]; then
    if [ ! -f "$FILE_PATH" ]; then
        exit 0
    fi

    HASH_BEFORE=$(md5sum "$FILE_PATH" | awk '{print $1}')
    
    # Run linting and formatting separately to catch all errors
    CHECK_OUT=$(ruff check --fix "$FILE_PATH" 2>&1)
    CHECK_EXIT=$?
    
    FORMAT_OUT=$(ruff format "$FILE_PATH" 2>&1)
    FORMAT_EXIT=$?
    
    HASH_AFTER=$(md5sum "$FILE_PATH" | awk '{print $1}')

    STATUS="SUCCESS"
    if [ $CHECK_EXIT -ne 0 ] || [ $FORMAT_EXIT -ne 0 ]; then
        STATUS="FAILED"
        # Combine outputs cleanly
        COMBINED_OUT=$(printf "--- Ruff Check ---\n%s\n\n--- Ruff Format ---\n%s" "$CHECK_OUT" "$FORMAT_OUT")
        jq -n --arg out "$COMBINED_OUT" \
          '{
            decision: "deny",
            reason: $out,
            hookSpecificOutput: {
              hookEventName: "AfterTool",
              additionalContext: $out
            }
          }'
    elif [ "$HASH_BEFORE" != "$HASH_AFTER" ]; then
        STATUS="MODIFIED"
        MSG=$(printf "Ruff auto-formatted/fixed %s.\n\nCheck output:\n%s\nFormat output:\n%s" "$FILE_PATH" "$CHECK_OUT" "$FORMAT_OUT")
        jq -n --arg msg "$MSG" '{systemMessage: $msg}'
    fi

    if [[ "$GEMINI_DEBUG_HOOKS" != "false" ]]; then
        mkdir -p "$LOG_DIR"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-ruff.sh [Session: $SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
fi
