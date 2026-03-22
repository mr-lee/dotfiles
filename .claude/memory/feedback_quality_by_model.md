---
name: Post-wave reviews must track quality scores per model
description: Security and code quality reviews must tag findings with which model produced the code, so we can evaluate quality vs cost tradeoffs data-driven.
type: feedback
---

Speed and token efficiency alone don't justify model selection. Post-wave reviews (security, code quality, doc quality) must:

1. Identify which model produced each file/change (from agent dispatch records or git metadata)
2. Rate quality per-file, tagged with the model
3. Feed model-to-quality data into metrics tooling for comparison

**Why:** "Haiku was 5x cheaper" is only half the story. If haiku-produced code has more bugs or security issues, the savings are illusory. We need the full picture: cost + quality + speed per model per task type.

**How to apply:** When dispatching post-wave review agents, include instructions to note which model produced each piece of code they're reviewing.
