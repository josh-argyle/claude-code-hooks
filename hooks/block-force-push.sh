#!/bin/sh

# Block force push operations hook for Claude Code
# Prevents dangerous force pushes that can destroy remote history

# Read JSON input from stdin
INPUT=$(cat)

# Debug logging
echo "$(date): Force push hook called" >> /tmp/force-push-debug.log
echo "INPUT: $INPUT" >> /tmp/force-push-debug.log

# Check if this is a Bash tool
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    echo "Is Bash command" >> /tmp/force-push-debug.log
    
    # Check for force push operations
    if echo "$INPUT" | grep -qE '"command":"[^"]*git[[:space:]]+push[[:space:]]+[^"]*--force' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*git[[:space:]]+push[[:space:]]+[^"]*-f[[:space:]]' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*git[[:space:]]+push[[:space:]]+.*[[:space:]]-f$'; then
        
        echo "BLOCKING force push!" >> /tmp/force-push-debug.log
        cat << 'EOFINNER'
{
  "decision": "block",
  "reason": "🚫 NO FORCE PUSH! This can destroy remote history and other developers' work. Use --force-with-lease carefully or create a new branch.",
  "systemMessage": "Force push blocked - use safer alternatives"
}
EOFINNER
        exit 0
    fi
fi

echo "ALLOWING (no force push found)" >> /tmp/force-push-debug.log
# Allow all other commands
echo '{"decision": "approve"}'
exit 0
