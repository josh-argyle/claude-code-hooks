#!/bin/bash

# Enhanced statusLine script for Claude Code
# Provides comprehensive development context including git, Node.js, and project info

# Read Claude Code context from stdin
input=$(cat)

# Extract context from Claude Code JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model_name=$(echo "$input" | jq -r '.model.display_name // ""')
output_style=$(echo "$input" | jq -r '.output_style.name // ""')

# Use current_dir or fallback to pwd
if [ -z "$current_dir" ] || [ "$current_dir" = "null" ]; then
    current_dir=$(pwd)
fi

# Color definitions (dimmed for status line)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
RESET='\033[0m'

# Build status line components
status_parts=()

# 1. User@hostname
status_parts+=("${GREEN}$(whoami)@$(hostname -s)${RESET}")

# 2. Current directory (basename only to save space)
dir_name=$(basename "$current_dir")
status_parts+=("${BLUE}$dir_name${RESET}")

# 3. Git branch (if in git repo)
if [ -d "$current_dir/.git" ] || git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
    cd "$current_dir" 2>/dev/null || true
    git_branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$git_branch" ]; then
        # Check for uncommitted changes
        if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
            git_status="*"
        else
            git_status=""
        fi
        status_parts+=("${YELLOW}$git_branch$git_status${RESET}")
    fi
fi

# 4. Node.js version
if command -v node >/dev/null 2>&1; then
    node_version=$(node --version 2>/dev/null | sed 's/^v//')
    if [ -n "$node_version" ]; then
        status_parts+=("${CYAN}node:$node_version${RESET}")
    fi
fi

# 5. Project info from package.json
if [ -f "$current_dir/package.json" ]; then
    project_name=$(jq -r '.name // ""' "$current_dir/package.json" 2>/dev/null)
    project_version=$(jq -r '.version // ""' "$current_dir/package.json" 2>/dev/null)
    if [ -n "$project_name" ] && [ "$project_name" != "null" ]; then
        if [ -n "$project_version" ] && [ "$project_version" != "null" ]; then
            status_parts+=("${PURPLE}$project_name:$project_version${RESET}")
        else
            status_parts+=("${PURPLE}$project_name${RESET}")
        fi
    fi
fi

# 6. Claude model info (if available and different from default)
if [ -n "$model_name" ] && [ "$model_name" != "null" ] && [ "$model_name" != "Claude 3.5 Sonnet" ]; then
    model_short=$(echo "$model_name" | sed 's/Claude //' | sed 's/ Sonnet//' | sed 's/3.5/3.5S/')
    status_parts+=("${GRAY}$model_short${RESET}")
fi

# 7. Timestamp
timestamp=$(date +"%H:%M")
status_parts+=("${GRAY}$timestamp${RESET}")

# Join all parts with separators
printf "%s" "${status_parts[0]}"
for i in "${status_parts[@]:1}"; do
    printf " | %s" "$i"
done