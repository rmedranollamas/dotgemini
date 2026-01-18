#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    exit 0
fi

if ! command -v mdformat &> /dev/null; then
    echo "Warning: mdformat is not installed." >&2
    exit 0
fi

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "n/a"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Use GEMINI_PROJECT_DIR if available, otherwise find log relative to the script
if [ -n "$GEMINI_PROJECT_DIR" ]; then
    LOG_FILE="$GEMINI_PROJECT_DIR/hooks/hook.log"
else
    # Fallback: log relative to the script's location
    LOG_FILE="$(dirname "$(readlink -f "$0")")/hook.log"
fi

if [[ "$FILE_PATH" == *.md ]]; then
    if [ ! -f "$FILE_PATH" ]; then
        exit 0
    fi

    HASH_BEFORE=$(md5sum "$FILE_PATH" | awk '{print $1}')
    FORMAT_OUT=$(mdformat "$FILE_PATH" 2>&1)
    EXIT_CODE=$?
    HASH_AFTER=$(md5sum "$FILE_PATH" | awk '{print $1}')

    STATUS="SUCCESS"
    if [ $EXIT_CODE -ne 0 ]; then
        STATUS="FAILED"
        jq -n --arg out "$FORMAT_OUT" '{decision: "deny", hookSpecificOutput: {hookEventName: "AfterTool", additionalContext: ("mdformat failed:\n" + $out)} }'
    elif [ "$HASH_BEFORE" != "$HASH_AFTER" ]; then
        STATUS="MODIFIED"
        jq -n --arg path "$FILE_PATH" --arg fmt "$FORMAT_OUT" '{systemMessage: ("mdformat auto-formatted " + $path + ". Output:\n" + $fmt)}'
    fi

    if [[ "$GEMINI_DEBUG_HOOKS" != "false" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-mdformat.sh [Session: $SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
fi
