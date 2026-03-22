---
name: Break agent tasks into fine-grained single-file units
description: Agents should do ONE focused thing (one file, one concern). Broad multi-file tasks cause context exhaustion and partial completion.
type: feedback
---

Agent tasks must be broken down as finely as possible — ideally one file or one concern per agent. Never give an agent a task that spans 4+ files across different layers (UI, routing, data, tests).

**Why:** Broad multi-file agent tasks frequently run out of context after writing tests but before implementing the features. This wastes a full agent run and requires re-dispatch.

**How to apply:** When planning an agent dispatch, decompose the task into the smallest independent units:
- Agent A: Modify one screen/component
- Agent B: Add a UI element to another screen
- Agent C: Wire up initialization/lifecycle in the app entry point
- Agent D: Write tests for all of the above

If agents A-C are writing to different files, they can run in parallel. Agent D depends on A-C completing. Partition work as finely as possible — the finer the decomposition, the more tasks qualify for cheaper models.
