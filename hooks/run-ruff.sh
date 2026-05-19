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

# Reliable log directory resolution
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
        if [[ "$CHECK_OUT" == *"SyntaxError"* ]] || [[ "$CHECK_OUT" == *"invalid-syntax"* ]] || [[ "$FORMAT_OUT" == *"failed to parse"* ]]; then
            REASON=$(printf "SYNTAX ERROR: I can't parse %s. Fix the broken Python structure before retrying: %s" "$FILE_PATH" "${CHECK_OUT}${FORMAT_OUT}")
        else
            REASON=$(printf "LINT/FORMAT FAILURE: Found issues in %s I can't auto-fix. Resolve these manually:\n\n--- Ruff Check ---\n%s\n\n--- Ruff Format ---\n%s" "$FILE_PATH" "$CHECK_OUT" "$FORMAT_OUT")
        fi
        jq -n --arg r "$REASON" \
            '{
                decision: "deny",
                reason: $r
            }'
    elif [ "$HASH_BEFORE" != "$HASH_AFTER" ]; then
        STATUS="MODIFIED"
        USER_MSG=$(printf "Auto-formatted/fixed %s." "$FILE_PATH")
        AGENT_MSG=$(printf "NOTE: I've auto-formatted %s and fixed minor lint issues to match project standards. Carry on." "$FILE_PATH")
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
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] run-ruff.sh [Session: $SESSION_ID] $STATUS: $FILE_PATH" >> "$LOG_FILE"
    fi
else
    echo '{"decision": "allow"}'
fi
