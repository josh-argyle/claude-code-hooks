#!/bin/sh

# Block mass file operations hook for Claude Code
# Prevents dangerous bulk file operations that could destroy data

# Read JSON input from stdin
INPUT=$(cat)

# Debug logging
echo "$(date): Mass file ops hook called" >> /tmp/mass-file-ops-debug.log
echo "INPUT: $INPUT" >> /tmp/mass-file-ops-debug.log

# Check if this is a Bash tool
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    echo "Is Bash command" >> /tmp/mass-file-ops-debug.log
    
    # Check for mass file operations
    if echo "$INPUT" | grep -qE '"command":"[^"]*find[[:space:]]+.*-delete' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*truncate[[:space:]]' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*>[[:space:]]*[^"]+\.(js|ts|css|html|json|md)' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*sed[[:space:]]+-i[[:space:]]' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*awk[[:space:]]+-i[[:space:]]+inplace'; then
        
        echo "BLOCKING mass file operation!" >> /tmp/mass-file-ops-debug.log
        cat << 'EOFINNER'
{
  "decision": "block",
  "reason": "💥 DANGEROUS! Mass file operation blocked. This could destroy data. Create backups first or move files to /trash instead.",
  "systemMessage": "Mass file operation blocked - use safer alternatives"
}
EOFINNER
        exit 0
    fi
fi

echo "ALLOWING (no mass file ops found)" >> /tmp/mass-file-ops-debug.log
# Allow all other commands
echo '{"decision": "approve"}'
exit 0
