---
name: Working style — solo with massive agent parallelism
description: User builds solo but leverages many subagents in wave-based parallel execution. Design-first, research-first, spec precisely before building.
type: feedback
---

Solo developer who uses many parallel subagents for execution. Key principles:

1. **Wave-based parallel execution is the default.** Don't sequence work that can be parallelized. Agents are tireless — use them.
2. **Research before building.** Launch background research agents to gather data before making architectural decisions. Don't proceed blindly.
3. **Spec precisely enough to pivot.** If a tech choice is wrong, there should be a clear blueprint for rebuilding — including a work distribution plan for parallel agents to execute.
4. **Design in Figma, iterate visually in code.** Wireframe/design first, then code. Not code-first.
5. **Think critically about all design and product decisions.** Make honest tradeoff assessments. Don't rubber-stamp choices — evaluate them.
6. **Retros are mandatory.** Use the retro process (Q/Spec/Eff scores, AGENTS.md improvement proposals).

**Why:** User wants high-quality output with efficient use of agent compute. Research and specs prevent wasted effort from wrong turns. Precise specs make pivots cheap because the work can be re-parallelized against the new target.

**How to apply:** Always plan in waves. Launch research before decisions. Write specs detailed enough that a haiku-model agent could implement them. Track retros and feed learnings back into AGENTS.md.
