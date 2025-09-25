#!/bin/sh

# Block edits to paths specified in protected-paths.json
# This provides a unified, configurable approach to protecting files/folders

# Path to the configuration file
CONFIG_FILE="$(dirname "$0")/../protected-paths.json"

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool name using jq
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Check if this is an editing tool
IS_EDITING_TOOL=false
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "MultiEdit" ]; then
    IS_EDITING_TOOL=true
fi

# Check if this is a Bash tool
IS_BASH_TOOL=false
if [ "$TOOL_NAME" = "Bash" ]; then
    IS_BASH_TOOL=true
fi

# If config file doesn't exist, allow operation
if [ ! -f "$CONFIG_FILE" ]; then
    cat << 'EOF'
{
  "decision": "approve"
}
EOF
    exit 0
fi

# Read protected paths from config
PROTECTED_PATHS=$(jq -c '.protectedPaths[]' "$CONFIG_FILE" 2>/dev/null)

# If we can't read the config, allow operation
if [ $? -ne 0 ] || [ -z "$PROTECTED_PATHS" ]; then
    cat << 'EOF'
{
  "decision": "approve"
}
EOF
    exit 0
fi

# Check each protected path
echo "$PROTECTED_PATHS" | while IFS= read -r path_config; do
    PATH_TO_PROTECT=$(echo "$path_config" | jq -r '.path')
    MESSAGE=$(echo "$path_config" | jq -r '.message')
    BLOCK_BASH=$(echo "$path_config" | jq -r '.blockBash // true')

    # For editing tools, check file_path parameter
    if [ "$IS_EDITING_TOOL" = true ]; then
        FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
        if [ -n "$FILE_PATH" ] && echo "$FILE_PATH" | grep -q "$PATH_TO_PROTECT"; then
            cat << EOF
{
  "decision": "block",
  "reason": "🚫 $MESSAGE",
  "systemMessage": "Protected path blocked: $PATH_TO_PROTECT"
}
EOF
            exit 0
        fi
    fi

    # For bash tools, check command parameter if blocking is enabled
    if [ "$IS_BASH_TOOL" = true ] && [ "$BLOCK_BASH" = true ]; then
        COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
        if [ -n "$COMMAND" ] && echo "$COMMAND" | grep -q "$PATH_TO_PROTECT"; then
            # Check for dangerous commands that could modify files
            if echo "$COMMAND" | grep -qE "\\b(rm|mv|cp|cat.*>|echo.*>|sed|awk|perl|python|node).*$(echo "$PATH_TO_PROTECT" | sed 's/\//\\//g')" || \
               echo "$COMMAND" | grep -qE "$(echo "$PATH_TO_PROTECT" | sed 's/\//\\//g').*\\b(>|>>)\\b"; then
                cat << EOF
{
  "decision": "block",
  "reason": "🚫 $MESSAGE",
  "systemMessage": "Protected path operation blocked: $PATH_TO_PROTECT"
}
EOF
                exit 0
            fi
        fi
    fi
done

# Allow all other operations
cat << 'EOF'
{
  "decision": "approve"
}
EOF
exit 0