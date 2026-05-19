#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    exit 0
fi

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ "$FILE_PATH" == *.md ]]; then
    exec "$(dirname "$0")/run-mdformat-real.sh" <<< "$INPUT"
elif [[ "$FILE_PATH" == *.go ]]; then
    # 1. Run gofmt
    FMT_RES=$("$(dirname "$0")/run-gofmt.sh" <<< "$INPUT")
    if echo "$FMT_RES" | jq -e '.decision == "deny"' > /dev/null; then
        echo "$FMT_RES"
        exit 0
    fi

    # 2. Run go vet
    VET_RES=$("$(dirname "$0")/run-govet.sh" <<< "$INPUT")
    if echo "$VET_RES" | jq -e '.decision == "deny"' > /dev/null; then
        echo "$VET_RES"
        exit 0
    fi

    # 3. Return fmt result (might contain auto-formatting notification)
    # If FMT_RES has a systemMessage, we should return it
    if echo "$FMT_RES" | jq -e '.systemMessage' > /dev/null; then
        echo "$FMT_RES"
    else
        echo '{"decision": "allow"}'
    fi
else
    echo '{"decision": "allow"}'
fi
