#!/usr/bin/env bash
# PreToolUse hook: validates proposed Go content with gofmt before writing.

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    echo '{"decision": "allow"}'
    exit 0
fi

if ! command -v gofmt &> /dev/null; then
    echo "Warning: gofmt is not installed." >&2
    echo '{"decision": "allow"}'
    exit 0
fi

INPUT=$(cat)
TMP_FILE=$(mktemp --suffix=.go)

# 1. Reconstruct proposed content to TMP_FILE
TARGET_FILE=$(echo "$INPUT" | python3 "$(dirname "$0")/get_proposed_content.py" "$TMP_FILE" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo '{"decision": "allow"}'
    rm -f "$TMP_FILE"
    exit 0
fi

# Only run on .go files
if [[ "$TARGET_FILE" != *.go ]]; then
    echo '{"decision": "allow"}'
    rm -f "$TMP_FILE"
    exit 0
fi

# 2. Check that gofmt produces no diff (i.e. content is already formatted)
FORMAT_OUT=$(gofmt -e "$TMP_FILE" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    REASON=$(printf "SYNTAX ERROR: gofmt can't parse %s. Fix the broken Go syntax before retrying:\n%s" "$(basename "$TARGET_FILE")" "$FORMAT_OUT")
    jq -n --arg r "$REASON" '{decision: "deny", reason: $r}'
    rm -f "$TMP_FILE"
    exit 0
fi

DIFF_OUT=$(gofmt -l "$TMP_FILE" 2>&1)
if [ -n "$DIFF_OUT" ]; then
    FORMATTED=$(gofmt "$TMP_FILE" 2>/dev/null)
    DIFF=$(diff <(cat "$TMP_FILE") <(echo "$FORMATTED"))
    REASON=$(printf "FORMATTING ERROR: %s is not gofmt-formatted. Please reformat using gofmt before retrying.\nDiff:\n%s" "$(basename "$TARGET_FILE")" "$DIFF")
    jq -n --arg r "$REASON" '{decision: "deny", reason: $r}'
    rm -f "$TMP_FILE"
    exit 0
fi

echo '{"decision": "allow"}'
rm -f "$TMP_FILE"