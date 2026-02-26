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

HOOK_DIR="$(dirname "$(readlink -f \"$0\")")"
if [ -n "$GEMINI_PROJECT_DIR" ]; then
    LOG_DIR="$GEMINI_PROJECT_DIR/.gemini"
else
    LOG_DIR="$HOOK_DIR"
fi
LOG_FILE="$LOG_DIR/hooks.log"

if [[ "$FILE_PATH" == *.md ]] && [[ "$FILE_PATH" != *agents/* ]]; then
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
        jq -n --arg out "$FORMAT_OUT" \
          '{ \
            decision: "deny", \
            reason: ("mdformat failed:\n" + $out), \
            hookSpecificOutput: { \
              hookEventName: "AfterTool", \
              additionalContext: ("mdformat failed:\n" + $out) \
            } \
          }'
    elif [ "$HASH_BEFORE" != "$HASH_AFTER" ]; then
        STATUS="MODIFIED"
        MSG=$(printf "mdformat auto-formatted %s.\n\nOutput:\n%s" "$FILE_PATH" "$FORMAT_OUT")
        jq -n --arg msg "$MSG" '{systemMessage: $msg}'
    fi

    if [[ "$GEMINI_DEBUG_HOOKS" != "false" ]]; then
        mkdir -p "$LOG_DIR"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-mdformat.sh [Session: $SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
fi

