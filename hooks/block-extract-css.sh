#!/bin/sh

# Block extract-css script execution hook for Claude Code
# Prevents running CSS extraction scripts without permission

# Read JSON input from stdin
INPUT=$(cat)

# Check if this is a Bash command and contains extract-css patterns
# Since JSON parsing fails due to unescaped newlines, check the raw input directly
IS_BASH_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    IS_BASH_TOOL=true
fi

# Check if this is a Bash command and contains extract-css patterns
if [ "$IS_BASH_TOOL" = true ] && echo "$INPUT" | grep -q 'extract-css'; then
    # Return JSON to block and send message to Claude
    cat << 'EOF'
{
  "decision": "block",
  "reason": "🚫 NO! Do not run the extract-css script. CSS classes should only be updated with explicit human approval.",
  "systemMessage": "Extract-CSS script execution blocked"
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