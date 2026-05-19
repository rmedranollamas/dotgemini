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
        echo '{"decision": "allow"}'
        exit 0
    fi

    # go vet on a single file requires it to be part of a package or standalone
    # We use 'go vet' on the file.
    VET_OUT=$(go vet "$FILE_PATH" 2>&1)
    VET_EXIT=$?

    STATUS="SUCCESS"
    if [ $VET_EXIT -ne 0 ]; then
        STATUS="FAILED"
        if [[ "$VET_OUT" == *"syntax error"* ]] || [[ "$VET_OUT" == *"expected"* ]]; then
            REASON=$(printf "SYNTAX ERROR: I can't parse %s. Fix the broken Go syntax before retrying: %s" "$FILE_PATH" "$VET_OUT")
        else
            REASON=$(printf "VET FAILURE: 'go vet' found issues in %s. Resolve these manually: %s" "$FILE_PATH" "$VET_OUT")
        fi
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
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-govet.sh [Session: $SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
else
    echo '{"decision": "allow"}'
fi