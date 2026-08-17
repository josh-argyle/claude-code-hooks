#!/bin/sh

# Block CSS file edits hook for Claude Code
# This prevents accidentally modifying CSS files without permission

# Read JSON input from stdin
INPUT=$(cat)

# Check if this is an editing tool
IS_EDITING_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Edit"' || \
   echo "$INPUT" | grep -q '"tool_name":"Write"' || \
   echo "$INPUT" | grep -q '"tool_name":"MultiEdit"'; then
    IS_EDITING_TOOL=true
fi

# Extract file path and check if it's actually a CSS file
if [ "$IS_EDITING_TOOL" = true ]; then
    FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)

    # Check if file path ends with CSS extension
    if echo "$FILE_PATH" | grep -qE '\.(css)$'; then
        # Return JSON to block and send message to Claude
        cat << 'EOF'
{
  "decision": "block",
  "reason": "🎨 CSS file edits blocked! Please reuse existing CSS classes and variables. Only ask the human to create new CSS if ABSOLUTELY necessary.",
  "systemMessage": "CSS modification blocked - reuse existing styles or request human approval"
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
