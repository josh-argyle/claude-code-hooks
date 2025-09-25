#!/bin/sh

# Block CSS file edits hook for Claude Code
# This prevents accidentally modifying CSS files without permission

# Read JSON input from stdin
INPUT=$(cat)

# Check if this is an editing tool and if file path contains .css
# Since JSON parsing fails due to unescaped newlines, check the raw input directly
IS_EDITING_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Edit"' || \
   echo "$INPUT" | grep -q '"tool_name":"Write"' || \
   echo "$INPUT" | grep -q '"tool_name":"MultiEdit"'; then
    IS_EDITING_TOOL=true
fi

# Check if this is a file editing tool and if the file path ends with .css
if [ "$IS_EDITING_TOOL" = true ] && echo "$INPUT" | grep -q '\.css'; then
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

# Allow all other commands - return JSON to allow
cat << 'EOF'
{
  "decision": "approve"
}
EOF
exit 0