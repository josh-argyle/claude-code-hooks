  #!/bin/sh

  # Block eslint-disable comments hook for Claude Code
  # Prevents adding eslint-disable comments to force proper fixes
  # ONLY blocks in actual code files (.js, .ts, etc), not in documentation

  # Read JSON input from stdin
  INPUT=$(cat)

  # Debug logging
  echo "$(date): ESLint-disable hook called" >> /tmp/eslint-disable-debug.log
  echo "INPUT: $INPUT" >> /tmp/eslint-disable-debug.log

  # Use grep to check for editing tools and eslint-disable patterns in the raw JSON
  if echo "$INPUT" | grep -q '"tool_name":"Edit"' || \
     echo "$INPUT" | grep -q '"tool_name":"Write"' || \
     echo "$INPUT" | grep -q '"tool_name":"MultiEdit"'; then

      echo "Is editing tool" >> /tmp/eslint-disable-debug.log

      # Extract file path to check extension
      FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)
      echo "File path: $FILE_PATH" >> /tmp/eslint-disable-debug.log

      # Only block in actual JavaScript/TypeScript code files
      IS_CODE_FILE=false
      if echo "$FILE_PATH" | grep -qE '\.(js|jsx|ts|tsx|mjs|cjs)$'; then
          IS_CODE_FILE=true
          echo "Is code file: true" >> /tmp/eslint-disable-debug.log
      else
          echo "Is code file: false" >> /tmp/eslint-disable-debug.log
      fi

      # Check if the new_string contains eslint-disable patterns
      if echo "$INPUT" | grep -q "eslint-disable"; then
          # ONLY block if it's a code file
          if [ "$IS_CODE_FILE" = true ]; then
              echo "BLOCKING eslint-disable in code file!" >> /tmp/eslint-disable-debug.log
              # Return JSON to block and send strong message to Claude
              cat << 'EOFINNER'
  {
    "decision": "block",
    "reason": "🚫 NO! Fix the actual problem instead of disabling ESLint! Don't use eslint-disable comments.",
    "systemMessage": "Attempt to add eslint-disable blocked - fix the underlying issue"
  }
EOFINNER
              exit 0
          else
              echo "ALLOWING eslint-disable in non-code file (documentation/CSS/config)" >> /tmp/eslint-disable-debug.log
          fi
      fi
  fi

  echo "ALLOWING (no eslint-disable found or non-code file)" >> /tmp/eslint-disable-debug.log
  # Allow all other commands - return JSON to allow
  cat << 'EOFINNER'
  {
    "decision": "approve"
  }
EOFINNER
  exit 0

