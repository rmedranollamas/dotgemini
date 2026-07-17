#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    echo '{"decision": "allow"}'
    exit 0
fi

INPUT=$(cat)
TMP_FILE=$(mktemp)

# 1. Reconstruct proposed content to TMP_FILE
TARGET_FILE=$(echo "$INPUT" | python3 "$(dirname "$0")/get_proposed_content.py" "$TMP_FILE" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo '{"decision": "allow"}'
    rm -f "$TMP_FILE"
    exit 0
fi

# Only run on .sh, .bash files
if [[ "$TARGET_FILE" != *.sh ]] && [[ "$TARGET_FILE" != *.bash ]]; then
    echo '{"decision": "allow"}'
    rm -f "$TMP_FILE"
    exit 0
fi


# 2. Check Shell syntax validity using bash -n
OUTPUT=$(bash -n "$TMP_FILE" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    REASON=$(printf "SYNTAX ERROR: I can't parse %s. Fix the broken Shell syntax before retrying: %s" "$(basename "$TARGET_FILE")" "$OUTPUT")
    jq -n --arg r "$REASON" '{decision: "deny", reason: $r}'
    rm -f "$TMP_FILE"
    exit 0
fi

echo '{"decision": "allow"}'
rm -f "$TMP_FILE"