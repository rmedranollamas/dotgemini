#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    echo '{"decision": "allow"}'
    exit 0
fi

if ! command -v ty &> /dev/null; then
    echo "Warning: ty is not installed." >&2
    echo '{"decision": "allow"}'
    exit 0
fi

INPUT=$(cat)
TMP_FILE=$(mktemp -u).py # ty needs python extension

# 1. Reconstruct proposed content to TMP_FILE
TARGET_FILE=$(echo "$INPUT" | python3 "$(dirname "$0")/get_proposed_content.py" "$TMP_FILE" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo '{"decision": "allow"}'
    rm -f "$TMP_FILE"
    exit 0
fi

# Only run on .py files
if [[ "$TARGET_FILE" != *.py ]]; then
    echo '{"decision": "allow"}'
    rm -f "$TMP_FILE"
    exit 0
fi


# 2. Check Python types using ty
OUTPUT=$(ty "$TMP_FILE" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    REASON=$(printf "TYPE ERROR: Type checking failed for %s. Fix the issues before retrying: %s" "$(basename "$TARGET_FILE")" "$OUTPUT")
    jq -n --arg r "$REASON" '{decision: "deny", reason: $r}'
    rm -f "$TMP_FILE"
    exit 0
fi

echo '{"decision": "allow"}'
rm -f "$TMP_FILE"
