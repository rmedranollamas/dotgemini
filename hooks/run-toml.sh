#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    exit 0
fi

if ! command -v python3 &> /dev/null; then
    echo "Warning: python3 is not installed." >&2
    exit 0
fi

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "n/a"')
export FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

HOOK_DIR="$(dirname "$(readlink -f "$0")")"
if [ -n "$GEMINI_PROJECT_DIR" ]; then
    LOG_DIR="$GEMINI_PROJECT_DIR/.gemini"
else
    LOG_DIR="$HOOK_DIR"
fi
LOG_FILE="$LOG_DIR/hooks.log"

if [[ "$FILE_PATH" == *.toml ]]; then
    if [ ! -f "$FILE_PATH" ]; then
        exit 0
    fi

    # Use environment variable to safely pass file path to python
    OUTPUT=$(python3 -c "
import os, sys
try:
    import tomllib
except ImportError:
    print('Warning: tomllib is only available in Python 3.11+. Skipping validation.')
    sys.exit(0)

path = os.environ.get('FILE_PATH')
if not path or not os.path.exists(path):
    sys.exit(0)

with open(path, 'rb') as f:
    tomllib.load(f)
" 2>&1)
    EXIT_CODE=$?

    STATUS="SUCCESS"
    if [ $EXIT_CODE -ne 0 ]; then
        STATUS="FAILED"
        REASON=$(printf "SYNTAX ERROR: I can't parse %s. Fix the broken TOML structure before retrying: %s" "$FILE_PATH" "$OUTPUT")
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
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-toml.sh [Session: $SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
else
    echo '{"decision": "allow"}'
fi
