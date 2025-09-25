#!/bin/sh

# Block ESLint config file edits hook for Claude Code
# This prevents accidentally editing eslint.config.js files

# Read JSON input from stdin
INPUT=$(cat)

# Check if this is an editing tool and if file path contains eslint.config.js
# Since JSON parsing fails due to unescaped newlines, check the raw input directly
IS_EDITING_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Edit"' || \
   echo "$INPUT" | grep -q '"tool_name":"Write"' || \
   echo "$INPUT" | grep -q '"tool_name":"MultiEdit"'; then
    IS_EDITING_TOOL=true
fi

# Check if this is a file editing tool and if the file path contains eslint.config.js
if [ "$IS_EDITING_TOOL" = true ] && echo "$INPUT" | grep -q 'eslint\.config\.js'; then
    # Return JSON to block and send message to Claude
    cat << 'EOF'
{
  "decision": "block",
  "reason": "🚫 ESLint config files cannot be modified. These files contain critical linting rules that should not be changed.",
  "systemMessage": "ESLint configuration file edit blocked for protection"
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