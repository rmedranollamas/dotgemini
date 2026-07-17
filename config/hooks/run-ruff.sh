#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    echo '{"decision": "allow"}'
    exit 0
fi

if ! command -v ruff &> /dev/null; then
    echo "Warning: ruff is not installed." >&2
    echo '{"decision": "allow"}'
    exit 0
fi

INPUT=$(cat)
TMP_FILE=$(mktemp -u).py # ruff requires extension

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


# 2. Run Ruff check (linting)
CHECK_OUT=$(ruff check "$TMP_FILE" 2>&1)
CHECK_EXIT=$?

# 3. Run Ruff format check
FORMAT_OUT=$(ruff format --check "$TMP_FILE" 2>&1)
FORMAT_EXIT=$?

if [ $CHECK_EXIT -ne 0 ] || [ $FORMAT_EXIT -ne 0 ]; then
    if [[ "$CHECK_OUT" == *"SyntaxError"* ]] || [[ "$CHECK_OUT" == *"invalid-syntax"* ]] || [[ "$FORMAT_OUT" == *"failed to parse"* ]]; then
        REASON=$(printf "SYNTAX ERROR: I can't parse %s. Fix the broken Python structure before retrying: %s" "$(basename "$TARGET_FILE")" "${CHECK_OUT}${FORMAT_OUT}")
    else
        REASON=$(printf "LINT/FORMAT FAILURE: Found issues in %s. Resolve these or format your Python code to match standards:\n\n--- Ruff Check ---\n%s\n\n--- Ruff Format ---\n%s" "$(basename "$TARGET_FILE")" "$CHECK_OUT" "$FORMAT_OUT")
    fi
    jq -n --arg r "$REASON" '{decision: "deny", reason: $r}'
    rm -f "$TMP_FILE"
    exit 0
fi

echo '{"decision": "allow"}'
rm -f "$TMP_FILE"
