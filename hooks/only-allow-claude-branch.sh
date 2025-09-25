#!/bin/sh

# Only allow git push to claude-code branch hook for Claude Code
# Blocks ALL git pushes except to claude-code branch

# Read JSON input from stdin
INPUT=$(cat)

# Check if this is a Bash command
# Since JSON parsing fails due to unescaped newlines, check the raw input directly
IS_BASH_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    IS_BASH_TOOL=true
fi

# Check if this is a git push command
if [ "$IS_BASH_TOOL" = true ] && echo "$INPUT" | grep -q 'git push'; then
    # ONLY allow if pushing to claude-code branch
    if echo "$INPUT" | grep -q 'claude-code'; then
        cat << 'EOF'
{
  "decision": "approve"
}
EOF
        exit 0
    else
        # Block ALL other git push attempts
        cat << 'EOF'
{
  "decision": "block",
  "reason": "🚫 NO! You can ONLY push to the 'claude-code' branch. Please use: git push origin claude-code",
  "systemMessage": "Git push blocked - only claude-code branch allowed"
}
EOF
        exit 0
    fi
fi

# Allow all non git-push commands
cat << 'EOF'
{
  "decision": "approve"
}
EOF
exit 0