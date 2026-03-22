---
name: Orchestrator must read orchestrator-guide.md on first turn and after compaction
description: The orchestrator agent must explicitly read docs/orchestrator-guide.md at conversation start and after any context compaction, since it's not auto-loaded like CLAUDE.md.
type: feedback
---

The orchestrator guide (docs/orchestrator-guide.md) contains dispatch protocol, merge protocol, failure recovery, and wave planning — critical orchestrator knowledge that is NOT in AGENTS.md/CLAUDE.md (which was slimmed down for executor context efficiency).

**Why:** AGENTS.md is auto-loaded (CLAUDE.md symlink) but orchestrator-guide.md is not. After context compaction, the orchestrator loses the guide content and drifts — dispatching overly broad agents, forgetting failure recovery steps, etc.

**How to apply:** On the FIRST turn of any conversation where you are acting as an orchestrator (planning waves, dispatching agents, managing backlog), read docs/orchestrator-guide.md. After any context compaction, read it again.
