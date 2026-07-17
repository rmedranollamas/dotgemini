#!/usr/bin/env bash
# PreToolUse hook: validates proposed Markdown content with mdformat before writing.

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    echo '{"decision": "allow"}'
    exit 0
fi

if ! command -v mdformat &> /dev/null; then
    echo "Warning: mdformat is not installed." >&2
    echo '{"decision": "allow"}'
    exit 0
fi

INPUT=$(cat)
TMP_FILE=$(mktemp --suffix=.md)

# 1. Reconstruct proposed content to TMP_FILE
TARGET_FILE=$(echo "$INPUT" | python3 "$(dirname "$0")/get_proposed_content.py" "$TMP_FILE" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo '{"decision": "allow"}'
    rm -f "$TMP_FILE"
    exit 0
fi

# Only run on .md files
if [[ "$TARGET_FILE" != *.md ]]; then
    echo '{"decision": "allow"}'
    rm -f "$TMP_FILE"
    exit 0
fi

# 2. Check markdown formatting by running mdformat on a copy and comparing
TMP_FORMATTED=$(mktemp --suffix=.md)
cp "$TMP_FILE" "$TMP_FORMATTED"
FORMAT_OUT=$(mdformat --wrap=no "$TMP_FORMATTED" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    REASON=$(printf "FORMATTING ERROR: mdformat failed for %s. Check for broken Markdown syntax before retrying:\n%s" "$(basename "$TARGET_FILE")" "$FORMAT_OUT")
    jq -n --arg r "$REASON" '{decision: "deny", reason: $r}'
    rm -f "$TMP_FILE" "$TMP_FORMATTED"
    exit 0
fi

if ! diff -q "$TMP_FILE" "$TMP_FORMATTED" > /dev/null 2>&1; then
    DIFF_OUT=$(diff "$TMP_FILE" "$TMP_FORMATTED")
    REASON=$(printf "FORMATTING ERROR: %s is not formatted correctly per mdformat (--wrap=no). Please reformat the Markdown to match project standards.\nDiff:\n%s" "$(basename "$TARGET_FILE")" "$DIFF_OUT")
    jq -n --arg r "$REASON" '{decision: "deny", reason: $r}'
    rm -f "$TMP_FILE" "$TMP_FORMATTED"
    exit 0
fi

echo '{"decision": "allow"}'
rm -f "$TMP_FILE" "$TMP_FORMATTED"