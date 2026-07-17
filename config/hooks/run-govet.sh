#!/usr/bin/env bash
# PreToolUse hook: validates proposed Go content with go vet before writing.

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    echo '{"decision": "allow"}'
    exit 0
fi

if ! command -v go &> /dev/null; then
    echo "Warning: go is not installed." >&2
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

# 2. go vet on a single standalone file via a temp package dir
TMP_PKG_DIR=$(mktemp -d)
TMP_PKG_FILE="$TMP_PKG_DIR/main.go"
cp "$TMP_FILE" "$TMP_PKG_FILE"

# Make sure directory is fully standalone by running go vet in it
VET_OUT=$(cd "$TMP_PKG_DIR" && go vet . 2>&1)
VET_EXIT=$?

rm -rf "$TMP_PKG_DIR"
rm -f "$TMP_FILE"

if [ $VET_EXIT -ne 0 ]; then
    if [[ "$VET_OUT" == *"syntax error"* ]] || [[ "$VET_OUT" == *"expected"* ]]; then
        REASON=$(printf "SYNTAX ERROR: go vet can't parse %s. Fix the broken Go syntax before retrying:\n%s" "$(basename "$TARGET_FILE")" "$VET_OUT")
    else
        REASON=$(printf "VET FAILURE: 'go vet' found issues in %s. Resolve these before retrying:\n%s" "$(basename "$TARGET_FILE")" "$VET_OUT")
    fi
    jq -n --arg r "$REASON" '{decision: "deny", reason: $r}'
    exit 0
fi

echo '{"decision": "allow"}'