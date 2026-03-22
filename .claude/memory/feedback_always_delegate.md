---
name: Always delegate code work to subagents
description: Never write code directly as orchestrator — always dispatch subagents for implementation, even for small changes.
type: feedback
---

NEVER do implementation work yourself in the main conversation. Always delegate to subagents via the Agent tool, even for seemingly small code changes.

**Why:** The user expects the orchestrator role to only plan, dispatch, and merge — not to read code, design solutions, and implement. Doing research inline bloats the main context and causes compaction.

**How to apply:** When the user asks for a code change, gather just enough context to write a clear spec, then immediately dispatch a subagent in a worktree to do the work. Don't read through multiple files yourself.
