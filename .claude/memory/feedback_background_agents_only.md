---
name: Background agents only — never block on subagents
description: All subagents must run in background. Never use foreground agents that block the conversation.
type: feedback
---

ALL subagents must use `run_in_background: true`. Never launch a foreground agent that blocks the conversation. The user wants to keep talking while agents work.

**Why:** Foreground agents block the conversation, preventing the user from interacting or giving direction. Background agents let the conversation continue while work happens in parallel.

**How to apply:** Every `Agent` tool call must include `run_in_background: true`. If you need the result before proceeding, tell the user what you launched and continue the conversation on other topics while waiting for the notification.
