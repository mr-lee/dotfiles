---
name: Use haiku for clearly-specced executor tasks
description: Fine-grained single-file tasks with clear specs should use model=haiku to save costs. Only use sonnet/opus for research, architecture, or judgment-heavy work.
type: feedback
---

When tasks are decomposed into single-file, clearly-specced units, use `model: "haiku"` on the Agent dispatch. The finer the decomposition, the more tasks qualify for haiku.

**Why:** Smaller tasks with clear specs don't need the reasoning power of sonnet/opus. Using haiku saves significant model costs and bandwidth. This is a direct benefit of the task decomposition SOP — better breakdown = cheaper execution.

**How to apply:**
- **haiku:** Single-file edits with clear requirements, writing tests for existing code, docs, adding a column + running codegen, adding a button to a screen
- **sonnet:** Research tasks, multi-file coordination, debugging, code review, tasks requiring judgment calls
- **opus:** Architecture decisions, complex system design, ambiguous specs needing interpretation

Default to haiku. Upgrade only when the task genuinely needs more reasoning.
