#!/bin/sh

# Block git commit --no-verify commands hook for Claude Code
# Prevents bypassing linting and pre-commit hooks

# Read JSON input from stdin
INPUT=$(cat)

# Check if this is a Bash command
# Since JSON parsing fails due to unescaped newlines, check the raw input directly
IS_BASH_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    IS_BASH_TOOL=true
fi

# Check if it's a git commit command with --no-verify flag
if [ "$IS_BASH_TOOL" = true ] && echo "$INPUT" | grep -q 'git commit' && echo "$INPUT" | grep -qE '(\-\-no-verify|\-n[^a-zA-Z])'; then
    # Return JSON to block and send message to Claude
    cat << 'EOF'
{
  "decision": "block",
  "reason": "🚫 NO! Do not use --no-verify to bypass linting! Fix the linting issues properly instead.",
  "systemMessage": "Git commit --no-verify blocked - fix linting issues instead"
}
EOF
    exit 0
fi

# Allow all other commands
cat << 'EOF'
{
  "decision": "approve"
}
EOF
exit 0