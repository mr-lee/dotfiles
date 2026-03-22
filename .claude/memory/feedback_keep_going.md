---
name: Don't wait for permission to dispatch planned waves
description: If waves are already planned and approved, dispatch them immediately. Only pull the andon cord for genuine blockers/ambiguity, not for permission to continue.
type: feedback
---

When waves are already planned and the user has approved the plan, dispatch them immediately without waiting. The orchestrator has an andon cord (AskUserQuestion) for genuine blockers, but should keep moving otherwise.

**Why:** The user doesn't want to be a bottleneck. Waiting for explicit "go" on already-approved work wastes time.

**How to apply:** After completing a wave, immediately dispatch the next planned wave. Only pause to ask the user when there's genuine ambiguity, a blocker, or an architectural decision that needs input.
