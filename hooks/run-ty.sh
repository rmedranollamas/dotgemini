#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    exit 0
fi

if ! command -v ty &> /dev/null; then
    echo "Warning: ty is not installed." >&2
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

if [[ "$FILE_PATH" == *.py ]]; then
    if [ ! -f "$FILE_PATH" ]; then
        exit 0
    fi

    OUTPUT=$(ty check "$FILE_PATH" 2>&1)
    EXIT_CODE=$?

    STATUS="SUCCESS"
    if [ $EXIT_CODE -ne 0 ]; then
        STATUS="FAILED"
        REASON=$(printf "TYPE ERROR: Type checking failed for %s. Ensure your types match the expected signatures: %s" "$FILE_PATH" "$OUTPUT")
        jq -n --arg r "$REASON" \
            '{
                decision: "deny",
                reason: $r
            }'
    else
        echo '{"decision": "allow"}'
    fi

    if [[ "$GEMINI_DEBUG_HOOKS" != "false" ]]; then
        mkdir -p "$LOG_DIR"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-ty.sh [Session: $SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
else
    echo '{"decision": "allow"}'
fi
