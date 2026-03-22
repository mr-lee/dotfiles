---
name: Agents must self-manage backlog and commits
description: Subagents must commit their own work and update the backlog themselves, not rely on the orchestrator to do it after.
type: feedback
---

Every subagent prompt MUST include instructions to:
1. **Commit their own work** before finishing — `git add` and `git commit` with a descriptive message.
2. **Update the backlog** — mark their task as in-progress at the start, and complete when done.
3. **Write a retro** — EVERY agent, no exceptions, writes a retro. Even fix-up agents, even small tasks. The retro is how we learn.

**Why:** Agents that create files but don't commit or update the backlog require manual orchestrator cleanup. This wastes orchestrator time and risks losing work if worktrees are cleaned up.

**How to apply:** Include these as explicit final steps in every agent prompt. Agents should write their retros to the project's retro directory as instructed.
