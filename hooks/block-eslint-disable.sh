#!/bin/sh

# Block eslint-disable comments hook for Claude Code
# Prevents adding eslint-disable comments to force proper fixes

# Read JSON input from stdin
INPUT=$(cat)

# Debug logging
echo "$(date): ESLint-disable hook called" >> /tmp/eslint-disable-debug.log
echo "INPUT: $INPUT" >> /tmp/eslint-disable-debug.log

# Use grep to check for editing tools and eslint-disable patterns in the raw JSON
if echo "$INPUT" | grep -q '"tool_name":"Edit"' || \
   echo "$INPUT" | grep -q '"tool_name":"Write"' || \
   echo "$INPUT" | grep -q '"tool_name":"MultiEdit"'; then

    echo "Is editing tool" >> /tmp/eslint-disable-debug.log

    # Check if the new_string contains eslint-disable patterns
    if echo "$INPUT" | grep -q "eslint-disable"; then
        echo "BLOCKING eslint-disable!" >> /tmp/eslint-disable-debug.log
        # Return JSON to block and send strong message to Claude
        cat << 'EOFINNER'
{
  "decision": "block",
  "reason": "🚫 NO! Fix the actual problem instead of disabling ESLint! Don't use eslint-disable comments.",
  "systemMessage": "Attempt to add eslint-disable blocked - fix the underlying issue"
}
EOFINNER
        exit 0
    fi
fi

echo "ALLOWING (no eslint-disable found)" >> /tmp/eslint-disable-debug.log
# Allow all other commands - return JSON to allow
cat << 'EOFINNER'
{
  "decision": "approve"
}
EOFINNER
exit 0
