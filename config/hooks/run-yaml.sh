#!/usr/bin/env bash

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed." >&2
    echo '{"decision": "allow"}'
    exit 0
fi

if ! command -v python3 &> /dev/null; then
    echo "Warning: python3 is not installed." >&2
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

# Only run on .yaml, .yml files
if [[ "$TARGET_FILE" != *.yaml ]] && [[ "$TARGET_FILE" != *.yml ]]; then
    echo '{"decision": "allow"}'
    rm -f "$TMP_FILE"
    exit 0
fi


# 2. Check YAML validity using python3 pyyaml
export TMP_FILE
OUTPUT=$(python3 -c "
import os, sys
try:
    import yaml
except ImportError:
    # PyYAML not installed. Fallback to allow.
    sys.exit(0)

path = os.environ.get('TMP_FILE')
if not path or not os.path.exists(path):
    sys.exit(0)

with open(path, 'r', encoding='utf-8') as f:
    try:
        yaml.safe_load(f)
    except Exception as e:
        print(str(e))
        sys.exit(1)
" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    REASON=$(printf "SYNTAX ERROR: I can't parse %s. Fix the broken YAML structure before retrying: %s" "$(basename "$TARGET_FILE")" "$OUTPUT")
    jq -n --arg r "$REASON" '{decision: "deny", reason: $r}'
    rm -f "$TMP_FILE"
    exit 0
fi

echo '{"decision": "allow"}'
rm -f "$TMP_FILE"