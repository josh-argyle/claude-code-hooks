#!/bin/sh

# Block allowed-css-classes.json file edits hook for Claude Code
# This prevents accidentally modifying the CSS classes whitelist

# Read JSON input from stdin
INPUT=$(cat)

# Check if this is an editing tool and if file path contains allowed-css-classes.json
# Since JSON parsing fails due to unescaped newlines, check the raw input directly
IS_EDITING_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Edit"' || \
   echo "$INPUT" | grep -q '"tool_name":"Write"' || \
   echo "$INPUT" | grep -q '"tool_name":"MultiEdit"'; then
    IS_EDITING_TOOL=true
fi

# Also check for Bash commands that might delete or modify the file
IS_BASH_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    IS_BASH_TOOL=true
fi

# Check if this is trying to modify allowed-css-classes.json
if [ "$IS_EDITING_TOOL" = true ] && echo "$INPUT" | grep -q 'allowed-css-classes\.json'; then
    # Return JSON to block and send message to Claude
    cat << 'EOF'
{
  "decision": "block",
  "reason": "🚫 NO! The allowed-css-classes.json file is protected. Only the human can update the CSS classes whitelist.",
  "systemMessage": "CSS classes whitelist file modification blocked"
}
EOF
    exit 0
fi

# Check for Bash commands that might delete or modify the file
if [ "$IS_BASH_TOOL" = true ] && echo "$INPUT" | grep -q 'allowed-css-classes\.json'; then
    # Block rm, mv, cp, and other file operations on this file
    if echo "$INPUT" | grep -qE '\b(rm|mv|cp|cat|echo|>|>>)\b.*allowed-css-classes\.json'; then
        cat << 'EOF'
{
  "decision": "block",
  "reason": "🚫 NO! The allowed-css-classes.json file is protected. Only the human can modify the CSS classes whitelist.",
  "systemMessage": "CSS classes whitelist file operation blocked"
}
EOF
        exit 0
    fi
fi

# Allow all other commands - return JSON to allow
cat << 'EOF'
{
  "decision": "approve"
}
EOF
exit 0