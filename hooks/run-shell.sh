#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    echo "{}"
    exit 0
fi

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "n/a"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

HOOK_DIR="$(dirname "$(readlink -f "$0")")"
if [ -n "$GEMINI_PROJECT_DIR" ]; then
    LOG_DIR="$GEMINI_PROJECT_DIR/.gemini"
else
    LOG_DIR="$HOOK_DIR"
fi
LOG_FILE="$LOG_DIR/hooks.log"
mkdir -p "$LOG_DIR"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(basename "$0") CALLED for $FILE_PATH" >> "$LOG_FILE"

if [[ "$FILE_PATH" == *.sh ]]; then
    if [ ! -f "$FILE_PATH" ]; then
        echo '{}'
        exit 0
    fi

    # Use bash -n for syntax checking
    OUTPUT=$(bash -n "$FILE_PATH" 2>&1)
    EXIT_CODE=$?

    STATUS="SUCCESS"
    if [ $EXIT_CODE -ne 0 ]; then
        STATUS="FAILED"
        REASON=$(printf "SYNTAX ERROR: I can't parse %s. Fix the broken Shell syntax before retrying: %s" "$FILE_PATH" "$OUTPUT")
        jq -n --arg r "$REASON" \
            '{
                decision: "deny",
                reason: $r
            }'
    else
        echo '{}'
    fi

    if [[ "$GEMINI_DEBUG_HOOKS" != "false" ]]; then
        mkdir -p "$LOG_DIR"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-shell.sh [Session: $SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
else
    echo '{}'
fi