#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    exit 0
fi

if ! command -v ruff &> /dev/null; then
    echo "Warning: ruff is not installed." >&2
    exit 0
fi

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "n/a"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -n "$GEMINI_PROJECT_DIR" ]; then
    LOG_DIR="$GEMINI_PROJECT_DIR/.gemini"
    LOG_FILE="$LOG_DIR/hooks.log"
else
    LOG_DIR="$(dirname "$(readlink -f "$0")")"
    LOG_FILE="$LOG_DIR/hook.log"
fi

if [[ "$FILE_PATH" == *.py ]]; then
    if [ ! -f "$FILE_PATH" ]; then
        exit 0
    fi

    HASH_BEFORE=$(md5sum "$FILE_PATH" | awk '{print $1}')
    CHECK_OUT=$(ruff check --fix "$FILE_PATH" 2>&1)
    EXIT_CODE=$?
    FORMAT_OUT=$(ruff format "$FILE_PATH" 2>&1)
    HASH_AFTER=$(md5sum "$FILE_PATH" | awk '{print $1}')

    STATUS="SUCCESS"
    if [ $EXIT_CODE -ne 0 ]; then
        STATUS="FAILED"
        jq -n --arg out "$CHECK_OUT" '{decision: "deny", hookSpecificOutput: {hookEventName: "AfterTool", additionalContext: ("Ruff linting failed:\n" + $out)} }'
    elif [ "$HASH_BEFORE" != "$HASH_AFTER" ]; then
        STATUS="MODIFIED"
        jq -n --arg path "$FILE_PATH" --arg fmt "$FORMAT_OUT" --arg chk "$CHECK_OUT" '{systemMessage: ("Ruff auto-formatted/fixed " + $path + ". Output:\n" + $fmt + "\n" + $chk)}'
    fi

    if [[ "$GEMINI_DEBUG_HOOKS" != "false" ]]; then
        mkdir -p "$LOG_DIR"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-ruff.sh [Session: $SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
fi
