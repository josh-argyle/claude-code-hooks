# Claude Code Hooks - Complete Implementation Guide

## Table of Contents
1. [Overview](#overview)
2. [Hook Types and Locations](#hook-types-and-locations)
3. [Critical Technical Details](#critical-technical-details)
4. [Hook Configuration](#hook-configuration)
5. [Implementation Guide](#implementation-guide)
6. [Working Hook Examples](#working-hook-examples)
7. [Testing and Debugging](#testing-and-debugging)
8. [Troubleshooting](#troubleshooting)
9. [Security Considerations](#security-considerations)

## Overview

Claude Code hooks allow you to intercept and control tool usage at various points in the execution lifecycle. Hooks can validate, modify, or block operations before they execute.

**Use Cases:**
- Block dangerous operations (server restarts, git pushes to main)
- Enforce coding standards (prevent eslint-disable comments)
- Protect critical files (CSS, config files)
- Add notifications and feedback
- Implement approval workflows

## Hook Types and Locations

### Global vs Project-Specific Hooks

**Global Hooks:**
- Location: `~/.claude/hooks/`
- Configuration: `~/.claude/settings.json`
- Apply to ALL Claude Code sessions
- Ideal for user-wide protections

**Project-Specific Hooks:**
- Location: `<project>/.claude/hooks/`
- Configuration: `<project>/.claude/settings.json`
- Apply only to specific project
- Ideal for project-specific rules

### Hook Events

- **PreToolUse:** Before tool execution (most common)
- **PostToolUse:** After tool execution
- **UserPromptSubmit:** Before user prompt processing
- **Stop:** When Claude stops
- **Notification:** For notification events
- **SessionStart/End:** Session lifecycle events

## Critical Technical Details

### ⚠️ JSON Parsing Issue

**CRITICAL:** Claude Code sends malformed JSON with unescaped newlines in string values. Standard JSON parsing with `jq` will fail silently.

**❌ This WILL NOT work:**
```bash
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool.parameters.file_path')
```

**✅ This WILL work:**
```bash
# Use direct pattern matching on raw input
IS_EDIT_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Edit"'; then
    IS_EDIT_TOOL=true
fi

# Check patterns directly in raw input
if echo "$INPUT" | grep -q 'eslint-disable'; then
    # Block the operation
fi
```

### JSON Input Format

The actual JSON structure received by hooks:

```json
{
  "session_id": "uuid",
  "transcript_path": "/path/to/transcript",
  "cwd": "/working/directory",
  "permission_mode": "acceptEdits",
  "hook_event_name": "PreToolUse",
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/path/to/file.js",
    "old_string": "original content",
    "new_string": "new content with\nunescaped newlines"
  }
}
```

**Note:** The `new_string` and `old_string` fields contain unescaped newlines that break JSON parsing.

## Hook Configuration

### Settings Format

Edit `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "/home/user/.claude/hooks/block-eslint-config.sh"
          },
          {
            "type": "command",
            "command": "/home/user/.claude/hooks/block-css-edits.sh"
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/home/user/.claude/hooks/block-server-start.sh"
          }
        ]
      }
    ]
  }
}
```

### Hook Response Formats

**Block Operation:**
```json
{
  "decision": "block",
  "reason": "🚫 Operation blocked! Explanation here.",
  "systemMessage": "Brief system message"
}
```

**Allow Operation:**
```json
{
  "decision": "approve"
}
```

**⚠️ Important:** Always use JSON responses, not exit codes. Exit code methods are deprecated.

## Implementation Guide

### Step 1: Create Hook Script

```bash
#!/bin/sh

# Hook description and purpose
# This prevents X operation because Y

# Read JSON input from stdin
INPUT=$(cat)

# Check tool type using pattern matching (NOT jq)
IS_TARGET_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Edit"' || \
   echo "$INPUT" | grep -q '"tool_name":"Write"' || \
   echo "$INPUT" | grep -q '"tool_name":"MultiEdit"'; then
    IS_TARGET_TOOL=true
fi

# Check for blocking conditions
if [ "$IS_TARGET_TOOL" = true ] && echo "$INPUT" | grep -q 'dangerous-pattern'; then
    # Block the operation
    cat << 'EOF'
{
  "decision": "block",
  "reason": "🚫 Clear explanation of why this is blocked.",
  "systemMessage": "Brief system message"
}
EOF
    exit 0
fi

# Allow all other operations
cat << 'EOF'
{
  "decision": "approve"
}
EOF
exit 0
```

### Step 2: Make Executable and Clean

```bash
chmod +x /path/to/hook.sh
sed -i 's/\r$//' /path/to/hook.sh  # Remove Windows line endings
```

### Step 3: Register in Settings

Add to appropriate hook array in `~/.claude/settings.json`

### Step 4: Restart Claude Code

**Critical:** Claude Code must be restarted for configuration changes to take effect.

## Working Hook Examples

### 1. Block ESLint Config Edits

**File:** `block-eslint-config.sh`
**Purpose:** Prevent editing eslint.config.js files

```bash
#!/bin/sh
INPUT=$(cat)

IS_EDITING_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Edit"' || \
   echo "$INPUT" | grep -q '"tool_name":"Write"' || \
   echo "$INPUT" | grep -q '"tool_name":"MultiEdit"'; then
    IS_EDITING_TOOL=true
fi

if [ "$IS_EDITING_TOOL" = true ] && echo "$INPUT" | grep -q 'eslint\.config\.js'; then
    cat << 'EOF'
{
  "decision": "block",
  "reason": "🚫 ESLint config files cannot be modified. These contain critical linting rules.",
  "systemMessage": "ESLint configuration file edit blocked"
}
EOF
    exit 0
fi

cat << 'EOF'
{"decision": "approve"}
EOF
exit 0
```

### 2. Block CSS File Edits

**File:** `block-css-edits.sh`
**Purpose:** Force reuse of existing CSS classes

```bash
#!/bin/sh
INPUT=$(cat)

IS_EDITING_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Edit"' || \
   echo "$INPUT" | grep -q '"tool_name":"Write"' || \
   echo "$INPUT" | grep -q '"tool_name":"MultiEdit"'; then
    IS_EDITING_TOOL=true
fi

if [ "$IS_EDITING_TOOL" = true ] && echo "$INPUT" | grep -q '\.css'; then
    cat << 'EOF'
{
  "decision": "block",
  "reason": "🎨 CSS file edits blocked! Please reuse existing CSS classes. Only ask human to create new CSS if ABSOLUTELY necessary.",
  "systemMessage": "CSS modification blocked - reuse existing styles"
}
EOF
    exit 0
fi

cat << 'EOF'
{"decision": "approve"}
EOF
exit 0
```

### 3. Block ESLint-Disable Comments

**File:** `block-eslint-disable.sh`
**Purpose:** Prevent shortcut eslint-disable comments

```bash
#!/bin/sh
INPUT=$(cat)

IS_EDITING_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Edit"' || \
   echo "$INPUT" | grep -q '"tool_name":"Write"' || \
   echo "$INPUT" | grep -q '"tool_name":"MultiEdit"'; then
    IS_EDITING_TOOL=true
fi

if [ "$IS_EDITING_TOOL" = true ]; then
    if echo "$INPUT" | grep -q "eslint-disable"; then
        cat << 'EOF'
{
  "decision": "block",
  "reason": "🚫 NO! Fix the actual problem instead of disabling ESLint! Don't use eslint-disable comments.",
  "systemMessage": "ESLint-disable comment blocked"
}
EOF
        exit 0
    fi
fi

cat << 'EOF'
{"decision": "approve"}
EOF
exit 0
```

### 4. Block Extract-CSS Script

**File:** `block-extract-css.sh`
**Purpose:** Prevent CSS whitelist updates without approval

```bash
#!/bin/sh
INPUT=$(cat)

IS_BASH_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    IS_BASH_TOOL=true
fi

if [ "$IS_BASH_TOOL" = true ] && echo "$INPUT" | grep -q 'extract-css'; then
    cat << 'EOF'
{
  "decision": "block",
  "reason": "🚫 NO! Do not run the extract-css script. CSS classes should only be updated with explicit human approval.",
  "systemMessage": "Extract-CSS script execution blocked"
}
EOF
    exit 0
fi

cat << 'EOF'
{"decision": "approve"}
EOF
exit 0
```

### 5. Git Push Branch Restriction

**File:** `only-allow-claude-branch.sh`
**Purpose:** Only allow pushes to claude-code branch

```bash
#!/bin/sh
INPUT=$(cat)

IS_BASH_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    IS_BASH_TOOL=true
fi

if [ "$IS_BASH_TOOL" = true ] && echo "$INPUT" | grep -q 'git push'; then
    # ONLY allow if pushing to claude-code branch
    if echo "$INPUT" | grep -q 'claude-code'; then
        cat << 'EOF'
{"decision": "approve"}
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

cat << 'EOF'
{"decision": "approve"}
EOF
exit 0
```

### 6. Server Start Protection

**File:** `block-server-start.sh`
**Purpose:** Prevent accidental server restarts

```bash
#!/bin/sh
INPUT=$(cat)

IS_BASH_TOOL=false
if echo "$INPUT" | grep -q '"tool_name":"Bash"'; then
    IS_BASH_TOOL=true
fi

if [ "$IS_BASH_TOOL" = true ] && echo "$INPUT" | grep -qiE "(npm|yarn|pnpm).+(dev|start|serve)|nodemon|node.+(app|server|index)|pm2.+start"; then
    cat << 'EOF'
{
  "decision": "block",
  "reason": "🚫 Server start command blocked! The server is already running. Do not start, restart, or kill the server.",
  "systemMessage": "Server start command blocked for protection"
}
EOF
    exit 0
fi

cat << 'EOF'
{"decision": "approve"}
EOF
exit 0
```

## Testing and Debugging

### Debug Logging

Add temporary debug logging to hooks:

```bash
# Debug logging
echo "HOOK: Called" >> /tmp/hook-debug.log
echo "HOOK: INPUT: $INPUT" >> /tmp/hook-debug.log
echo "HOOK: TOOL_NAME detected: $IS_TARGET_TOOL" >> /tmp/hook-debug.log

# Check debug log
cat /tmp/hook-debug.log
```

### Manual Testing

Test hooks manually:
```bash
# Test specific patterns
echo '{"tool_name":"Edit","tool_input":{"file_path":"test.css"}}' | /path/to/hook.sh

# Test in Claude Code
# Try the operation the hook should block
```

### Verification Steps

1. Create hook script with debug logging
2. Test manually with sample JSON
3. Register in settings.json
4. Restart Claude Code
5. Test actual operations
6. Remove debug logging
7. Final verification

## Troubleshooting

### Common Issues

**Hook not running at all:**
- Check file permissions (`chmod +x`)
- Verify path in settings.json is correct
- Restart Claude Code after configuration changes
- Check for syntax errors in JSON configuration

**Hook not blocking expected operations:**
- Add debug logging to see what input is received
- Verify pattern matching logic
- Check for carriage returns (`sed -i 's/\r$//' hookfile.sh`)
- Ensure using pattern matching, not jq parsing

**Multiple hooks interfering:**
- Hooks run in parallel for same matcher
- Each hook can independently block or allow
- Check hook execution order in settings.json

**JSON validation errors:**
- Ensure JSON response format is correct
- Use single quotes around EOF markers
- Validate JSON syntax

### Debug Commands

```bash
# Check hook execution
tail -f /tmp/hook-debug.log

# Verify hook registration
cat ~/.claude/settings.json | jq '.hooks'

# Test hook manually
echo 'test-json' | /path/to/hook.sh

# Check file permissions
ls -la ~/.claude/hooks/
```

## Security Considerations

### Best Practices

1. **Validate all inputs:** Don't trust hook input data
2. **Use whitelist approach:** Block by default, allow specific patterns
3. **Minimal permissions:** Hooks run with user permissions
4. **No external dependencies:** Keep hooks self-contained
5. **Clear error messages:** Help users understand why operations are blocked

### Dangerous Patterns to Avoid

- Don't use `eval` or dynamic code execution
- Don't trust file paths without validation
- Don't expose sensitive information in error messages
- Don't create hooks that can be easily bypassed

### Hook Isolation

- Each hook runs independently
- Hooks cannot communicate with each other
- Hooks have access to full system permissions
- Use principle of least privilege

## Advanced Usage

### Pattern Matching Tips

```bash
# Case-insensitive matching
echo "$INPUT" | grep -qi "pattern"

# Multiple patterns
echo "$INPUT" | grep -qE "(pattern1|pattern2)"

# Exact word boundaries
echo "$INPUT" | grep -q '\bexact-word\b'

# File extensions
echo "$INPUT" | grep -q '\.js$'
```

### Complex Conditions

```bash
# Multiple checks
if [ "$IS_EDIT_TOOL" = true ] && \
   echo "$INPUT" | grep -q 'dangerous-pattern' && \
   echo "$INPUT" | grep -v 'safe-exception'; then
    # Block operation
fi
```

### Dynamic Responses

```bash
# Extract specific information for better error messages
if echo "$INPUT" | grep -q 'specific-pattern'; then
    DETECTED_ISSUE=$(echo "$INPUT" | grep -o 'pattern-details')
    cat << EOF
{
  "decision": "block",
  "reason": "🚫 Detected issue: $DETECTED_ISSUE. Please fix this first.",
  "systemMessage": "Operation blocked due to detected issue"
}
EOF
    exit 0
fi
```

---

## Summary

Claude Code hooks provide powerful control over tool execution. The key to successful implementation is understanding the JSON parsing limitations and using direct pattern matching instead of JSON parsers. Always test thoroughly and restart Claude Code after configuration changes.

For questions or issues, refer to the official Claude Code documentation or this troubleshooting guide.