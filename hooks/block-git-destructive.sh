#!/bin/sh

# Block destructive git operations hook for Claude Code
# Prevents operations that permanently destroy changes without recovery

# Read JSON input from stdin
INPUT=$(cat)

# Debug logging
echo "$(date): Git destructive hook called" >> /tmp/git-destructive-debug.log
echo "INPUT: $INPUT" >> /tmp/git-destructive-debug.log

# Check if this is a Bash tool
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    echo "Is Bash command" >> /tmp/git-destructive-debug.log
    
    # Check for destructive git operations
    if echo "$INPUT" | grep -qE '"command":"[^"]*git[[:space:]]+reset[[:space:]]+--hard' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*git[[:space:]]+clean[[:space:]]+-[^"]*[fd]' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*git[[:space:]]+checkout[[:space:]]+--[[:space:]]+\.' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*git[[:space:]]+checkout[[:space:]]+--[[:space:]]+[^"]*'; then
        
        echo "BLOCKING destructive git operation!" >> /tmp/git-destructive-debug.log
        cat << 'EOFINNER'
{
  "decision": "block",
  "reason": "⚠️ STOP! This will permanently destroy changes! Create a backup first or use 'git stash' to save work safely.",
  "systemMessage": "Destructive git operation blocked - save changes first"
}
EOFINNER
        exit 0
    fi
fi

echo "ALLOWING (no destructive git found)" >> /tmp/git-destructive-debug.log
# Allow all other commands
echo '{"decision": "approve"}'
exit 0
