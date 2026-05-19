#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    exit 0
fi

if ! command -v go &> /dev/null; then
    echo "Warning: go is not installed." >&2
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

if [[ "$FILE_PATH" == *.go ]]; then
    if [ ! -f "$FILE_PATH" ]; then
        exit 0
    fi

    HASH_BEFORE=$(md5sum "$FILE_PATH" | awk '{print $1}')
    FORMAT_OUT=$(gofmt -w "$FILE_PATH" 2>&1)
    EXIT_CODE=$?
    HASH_AFTER=$(md5sum "$FILE_PATH" | awk '{print $1}')

    STATUS="SUCCESS"
    if [ $EXIT_CODE -ne 0 ]; then
        STATUS="FAILED"
        REASON=$(printf "FORMATTING ERROR: I can't format %s using gofmt. Check for broken Go syntax: %s" "$FILE_PATH" "$FORMAT_OUT")
        jq -n --arg r "$REASON" \
            '{
                decision: "deny",
                reason: $r
            }'
    elif [ "$HASH_BEFORE" != "$HASH_AFTER" ]; then
        STATUS="MODIFIED"
        USER_MSG=$(printf "Auto-formatted %s." "$FILE_PATH")
        AGENT_MSG=$(printf "NOTE: I've auto-formatted %s using gofmt to match Go standards. Carry on." "$FILE_PATH")
        jq -n --arg u "$USER_MSG" --arg a "$AGENT_MSG" \
            '{
                systemMessage: $u,
                hookSpecificOutput: {
                    hookEventName: "AfterTool",
                    additionalContext: $a
                }
            }'
    fi

    if [[ "$GEMINI_DEBUG_HOOKS" != "false" ]]; then
        mkdir -p "$LOG_DIR"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-gofmt.sh [Session: $SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
fi