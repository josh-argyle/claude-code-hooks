#!/bin/sh

# Block branch deletion operations hook for Claude Code
# Prevents accidental deletion of branches with potentially unmerged work

# Read JSON input from stdin
INPUT=$(cat)

# Debug logging
echo "$(date): Branch delete hook called" >> /tmp/branch-delete-debug.log
echo "INPUT: $INPUT" >> /tmp/branch-delete-debug.log

# Check if this is a Bash tool
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    echo "Is Bash command" >> /tmp/branch-delete-debug.log
    
    # Check for branch deletion operations
    if echo "$INPUT" | grep -qE '"command":"[^"]*git[[:space:]]+branch[[:space:]]+-D[[:space:]]' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*git[[:space:]]+push[[:space:]]+[^"]*--delete[[:space:]]' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*git[[:space:]]+push[[:space:]]+origin[[:space:]]+:[^"]*'; then
        
        echo "BLOCKING branch deletion!" >> /tmp/branch-delete-debug.log
        cat << 'EOFINNER'
{
  "decision": "block",
  "reason": "⚠️ Branch deletion blocked! Ensure work is merged/backed up first. Use 'git branch -d' for safe deletion of merged branches.",
  "systemMessage": "Branch deletion blocked - verify work is saved"
}
EOFINNER
        exit 0
    fi
fi

echo "ALLOWING (no branch delete found)" >> /tmp/branch-delete-debug.log
# Allow all other commands
echo '{"decision": "approve"}'
exit 0
