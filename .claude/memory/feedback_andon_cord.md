---
name: Andon cord — agents must escalate uncertainty
description: Subagents must stop and escalate when encountering ambiguity, not guess. Use AskUserQuestion to resolve with user.
type: feedback
---

Every subagent prompt MUST include an escalation/andon cord instruction: if there's ANY uncertainty, spec ambiguity, or critical issue, the agent should STOP immediately, write a clear `ESCALATION:` message in its output, and exit. The orchestrator then uses AskUserQuestion to resolve with the user before resuming.

**Why:** User wants problems surfaced early, not hidden. A 5-minute escalation prevents a 5-hour dead end. Agents should never guess at unclear requirements or push through uncertainty.

**How to apply:** Include the andon cord instruction in every subagent prompt. When an agent returns with an ESCALATION prefix, use AskUserQuestion before launching any follow-up work.
