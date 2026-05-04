#!/bin/sh

# Block server start commands hook for Claude Code
# This prevents accidentally starting servers when they're already running

# Read JSON input from stdin
INPUT=$(cat)

# Check if this is a Bash command and contains server start patterns
# Since JSON parsing fails due to unescaped newlines, check the raw input directly
IS_BASH_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    IS_BASH_TOOL=true
fi

# Check if this is a Bash command and contains server start patterns
if [ "$IS_BASH_TOOL" = true ] && echo "$INPUT" | grep -qiE "(npm|yarn|pnpm).+(dev|start|serve)|nodemon|node.+(app|server|index)|pm2.+start|python.+(app|server|main)|flask.+run|django.+runserver"; then
    # Return JSON to block and send message to Claude
    cat << 'EOF'
{
  "decision": "block",
  "reason": "🚫 Server start command blocked! The server is already running with nodemon. Do not start, restart, or kill the server.",
  "systemMessage": "Server start command blocked for protection"
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