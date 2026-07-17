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

# Only run on .json, .jsonl files
if [[ "$TARGET_FILE" != *.json ]] && [[ "$TARGET_FILE" != *.jsonl ]]; then
    echo '{"decision": "allow"}'
    rm -f "$TMP_FILE"
    exit 0
fi


# 2. Check JSON validity
JQ_ARGS="."
if [[ "$TARGET_FILE" == *.jsonl ]]; then
    JQ_ARGS="-c ."
fi

if ! jq $JQ_ARGS "$TMP_FILE" > /dev/null 2>&1; then
    OUTPUT=$(jq $JQ_ARGS "$TMP_FILE" 2>&1 > /dev/null)
    REASON=$(printf "SYNTAX ERROR: I can't parse %s. Fix the broken JSON structure before retrying: %s" "$(basename "$TARGET_FILE")" "$OUTPUT")
    jq -n --arg r "$REASON" '{decision: "deny", reason: $r}'
    rm -f "$TMP_FILE"
    exit 0
fi

# 3. Check JSON formatting
TMP_FORMATTED=$(mktemp)
jq $JQ_ARGS "$TMP_FILE" > "$TMP_FORMATTED" 2> /dev/null
if ! diff -q "$TMP_FILE" "$TMP_FORMATTED" > /dev/null 2>&1; then
    REASON=$(printf "FORMATTING ERROR: %s is not formatted correctly. Please format the JSON to match project standards." "$(basename "$TARGET_FILE")")
    jq -n --arg r "$REASON" '{decision: "deny", reason: $r}'
    rm -f "$TMP_FILE" "$TMP_FORMATTED"
    exit 0
fi

echo '{"decision": "allow"}'
rm -f "$TMP_FILE" "$TMP_FORMATTED"