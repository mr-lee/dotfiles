---
name: Never launch foreground agents
description: All subagents must run in background (run_in_background: true). Never block the conversation waiting for an agent.
type: feedback
---

NEVER launch a foreground agent. Every Agent tool call must use `run_in_background: true`. There are NO exceptions.

**Why:** Foreground agents block the entire conversation. The user can't interact, give feedback, or course-correct while waiting. Background agents let the conversation continue.

**How to apply:** Every single Agent dispatch must have `run_in_background: true`. If you need the result before proceeding, tell the user what you dispatched and wait for the notification — don't block.
