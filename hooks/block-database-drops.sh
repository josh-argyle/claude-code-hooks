#!/bin/sh

# Block database destructive operations hook for Claude Code
# Prevents dangerous database operations that permanently destroy data

# Read JSON input from stdin
INPUT=$(cat)

# Debug logging
echo "$(date): Database drops hook called" >> /tmp/database-drops-debug.log
echo "INPUT: $INPUT" >> /tmp/database-drops-debug.log

# Check if this is a Bash tool
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    echo "Is Bash command" >> /tmp/database-drops-debug.log
    
    # Check for dangerous database operations
    if echo "$INPUT" | grep -qiE '"command":"[^"]*DROP[[:space:]]+DATABASE' || \
       echo "$INPUT" | grep -qiE '"command":"[^"]*DROP[[:space:]]+TABLE' || \
       echo "$INPUT" | grep -qiE '"command":"[^"]*TRUNCATE[[:space:]]+TABLE' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*db\.[^"]*\.drop\(' || \
       echo "$INPUT" | grep -qE '"command":"[^"]*db\.dropDatabase\(' || \
       echo "$INPUT" | grep -qiE '"command":"[^"]*DELETE[[:space:]]+FROM[[:space:]]+[^"]*WHERE[[:space:]]*[^"]*='; then
        
        echo "BLOCKING database destruction!" >> /tmp/database-drops-debug.log
        cat << 'EOFINNER'
{
  "decision": "block",
  "reason": "🗄️ DATABASE DESTRUCTION BLOCKED! Never drop production data. Create proper backups first and use staging environment for testing.",
  "systemMessage": "Database destruction blocked - protect your data"
}
EOFINNER
        exit 0
    fi
fi

echo "ALLOWING (no database drops found)" >> /tmp/database-drops-debug.log
# Allow all other commands
echo '{"decision": "approve"}'
exit 0
