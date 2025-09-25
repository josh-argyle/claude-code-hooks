#!/bin/sh

# Block rm commands and redirect to /trash directory
# Prevents accidental file deletion by requiring use of /trash

# Read JSON input from stdin
INPUT=$(cat)

# Debug logging
echo "$(date): rm-blocking hook called" >> /tmp/rm-block-debug.log
echo "INPUT: $INPUT" >> /tmp/rm-block-debug.log

# Check if this is a Bash tool
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    echo "Is Bash command" >> /tmp/rm-block-debug.log
    
    # Check for rm commands in various patterns
    if echo "$INPUT" | grep -qE '"command":"[^"]*[[:space:]]+rm[[:space:]]' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*;[[:space:]]*rm[[:space:]]' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*&&[[:space:]]*rm[[:space:]]' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*\|\|[[:space:]]*rm[[:space:]]' || \
       echo "$INPUT" | grep -qE '"command":"rm[[:space:]]'; then
        
        echo "BLOCKING rm command!" >> /tmp/rm-block-debug.log
        cat << 'EOFINNER'
{
  "decision": "block",
  "reason": "🗑️ DO NOT use rm! Move files to /trash directory instead. Use: mv <file> /trash/",
  "systemMessage": "rm command blocked - use /trash directory for safe deletion"
}
EOFINNER
        exit 0
    fi
fi

echo "ALLOWING (no rm found)" >> /tmp/rm-block-debug.log
# Allow all other commands
echo '{"decision": "approve"}'
exit 0
