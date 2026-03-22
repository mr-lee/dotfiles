---
name: NEVER do implementation work yourself — always use subagents
description: The orchestrator must NEVER edit files, write code, or do merges directly. Always dispatch a subagent, even for small fixes, merge conflicts, or worktree extraction.
type: feedback
---

The orchestrator NEVER does implementation work directly. This includes:
- Fixing failed agent work
- Merging worktree branches that have conflicts
- Editing files to integrate changes
- "Small" fixes that seem trivial

**Why:** The user's standard is absolute: orchestrator orchestrates, subagents implement. No exceptions.

**How to apply:** On ANY work that involves reading + editing files: dispatch a subagent. For merges where the worktree diverged and needs selective file extraction + conflict resolution, dispatch a merge agent with clear instructions on what to extract and how to integrate. The only things the orchestrator does directly are: git commands (log, branch, worktree list), reading files for context to write agent prompts, and backlog/memory updates.
