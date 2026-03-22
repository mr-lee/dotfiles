---
name: Squash and merge, not merge commits
description: Always use squash merge when merging worktree branches. Clean linear history preferred.
type: feedback
---

When merging worktree branches into main, always use `git merge --squash` followed by a single commit — NOT regular merge commits.

**Why:** User prefers clean, linear git history. Merge commits clutter the log with branch topology noise. Each worktree's work should land as a single descriptive commit on main.

**How to apply:**
```bash
git merge --squash <branch>
git commit -m "descriptive message"
```
Not: `git merge <branch> --no-edit`

Include this instruction in merge agent prompts. Individual agents committing within their worktrees can make multiple commits (it helps their process), but the merge into main should squash them.
