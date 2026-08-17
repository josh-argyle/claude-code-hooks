---
name: worktree-from-head
description: Worktrees must branch from HEAD (claude-code), not origin/master — verify baseRef is "head" not "fresh"
metadata:
  type: feedback
---

Always use `worktree.baseRef: "head"` so worktrees branch from the current HEAD (usually `claude-code`), not from `origin/master`.

**Why:** The push hook only allows pushing to `claude-code`. If a worktree branches from `origin/master`, the commit can't be pushed directly and requires a cherry-pick to get it onto `claude-code` — messy and error-prone. Branching from HEAD means the worktree branch is a child of `claude-code`, so `git merge` back is a clean fast-forward.

**How to apply:** After creating a worktree, verify it branched from the current branch (e.g. `claude-code`), not from `origin/master`. The global `~/.claude/settings.json` has `worktree.baseRef: "head"` configured. If using `EnterWorktree`, this is automatic. If manually creating with `git worktree add`, base it off the current branch.
