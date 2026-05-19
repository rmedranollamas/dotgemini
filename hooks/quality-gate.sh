#!/usr/bin/env bash

# Master Quality Gate Dispatcher
# This script routes file modifications to the appropriate validator/formatter.

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 1. Global Ignore Patterns
# Skip checks for directories that contain agent logic, skill docs, or session history.
if [[ "$FILE_PATH" == *agents/* ]] || [[ "$FILE_PATH" == *skills/* ]] || [[ "$FILE_PATH" == *history/* ]] || [[ "$FILE_PATH" == *tmp/* ]]; then
    echo '{"decision": "allow"}'
    exit 0
fi

# 2. Dispatch by extension
if [[ "$FILE_PATH" == *.md ]]; then
    exec "$(dirname "$0")/run-mdformat-real.sh" <<< "$INPUT"

elif [[ "$FILE_PATH" == *.go ]]; then
    # Go: fmt then vet
    FMT_RES=$("$(dirname "$0")/run-gofmt.sh" <<< "$INPUT")
    if echo "$FMT_RES" | jq -e '.decision == "deny"' > /dev/null; then
        echo "$FMT_RES"
        exit 0
    fi
    VET_RES=$("$(dirname "$0")/run-govet.sh" <<< "$INPUT")
    if echo "$VET_RES" | jq -e '.decision == "deny"' > /dev/null; then
        echo "$VET_RES"
        exit 0
    fi
    # Prefer returning the auto-formatting message if it exists
    if echo "$FMT_RES" | jq -e '.systemMessage' > /dev/null; then
        echo "$FMT_RES"
    else
        echo '{"decision": "allow"}'
    fi

elif [[ "$FILE_PATH" == *.py ]]; then
    # Python: ruff (lint/format) then ty (types)
    RUFF_RES=$("$(dirname "$0")/run-ruff.sh" <<< "$INPUT")
    if echo "$RUFF_RES" | jq -e '.decision == "deny"' > /dev/null; then
        echo "$RUFF_RES"
        exit 0
    fi
    TY_RES=$("$(dirname "$0")/run-ty.sh" <<< "$INPUT")
    if echo "$TY_RES" | jq -e '.decision == "deny"' > /dev/null; then
        echo "$TY_RES"
        exit 0
    fi
    # Prefer returning the auto-formatting/fix message if it exists
    if echo "$RUFF_RES" | jq -e '.systemMessage' > /dev/null; then
        echo "$RUFF_RES"
    else
        echo '{"decision": "allow"}'
    fi

elif [[ "$FILE_PATH" == *.json ]]; then
    exec "$(dirname "$0")/run-json.sh" <<< "$INPUT"

elif [[ "$FILE_PATH" == *.toml ]]; then
    exec "$(dirname "$0")/run-toml.sh" <<< "$INPUT"

else
    # Default allow for all other file types
    echo '{"decision": "allow"}'
fi
