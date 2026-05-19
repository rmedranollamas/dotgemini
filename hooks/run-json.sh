#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
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

if [[ "$FILE_PATH" == *.json ]]; then
    if [ ! -f "$FILE_PATH" ]; then
        exit 0
    fi

    HASH_BEFORE=$(md5sum "$FILE_PATH" | awk '{print $1}')
    
    # Use a temporary file for formatting to avoid truncation on error
    TMP_FILE=$(mktemp)
    if jq . "$FILE_PATH" > "$TMP_FILE" 2> /dev/null; then
        mv "$TMP_FILE" "$FILE_PATH"
        EXIT_CODE=0
    else
        OUTPUT=$(jq . "$FILE_PATH" 2>&1 > /dev/null)
        EXIT_CODE=$?
        rm -f "$TMP_FILE"
    fi

    HASH_AFTER=$(md5sum "$FILE_PATH" | awk '{print $1}')

    STATUS="SUCCESS"
    if [ $EXIT_CODE -ne 0 ]; then
        STATUS="FAILED"
        REASON=$(printf "SYNTAX ERROR: I can't parse %s. Fix the broken JSON structure before retrying: %s" "$FILE_PATH" "$OUTPUT")
        jq -n --arg r "$REASON" \
            '{
                decision: "deny",
                reason: $r
            }'
    elif [ "$HASH_BEFORE" != "$HASH_AFTER" ]; then
        STATUS="MODIFIED"
        USER_MSG=$(printf "Auto-formatted %s." "$FILE_PATH")
        AGENT_MSG=$(printf "NOTE: I've auto-formatted %s using jq to match project standards. Carry on." "$FILE_PATH")
        jq -n --arg u "$USER_MSG" --arg a "$AGENT_MSG" \
            '{
                systemMessage: $u,
                hookSpecificOutput: {
                    hookEventName: "AfterTool",
                    additionalContext: $a
                }
            }'
    else
        echo '{"decision": "allow"}'
    fi

    if [[ "$GEMINI_DEBUG_HOOKS" != "false" ]]; then
        mkdir -p "$LOG_DIR"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-json.sh [Session: $SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
else
    echo '{"decision": "allow"}'
fi