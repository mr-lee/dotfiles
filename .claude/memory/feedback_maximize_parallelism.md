---
name: Maximize parallelism — parallelize across domains, serialize within
description: Always maximize parallel agent dispatch. Parallelize across different domains, serialize within the same domain.
type: feedback
---

Maximize parallelism aggressively. The rule of thumb:
- **Parallelize across domains:** Different files, different concerns, different areas of the codebase → separate agents in parallel
- **Serialize within a domain:** Work that shares deep context and builds on itself → one agent

When in doubt, lean toward MORE parallelism, not less. Agents are cheap and tireless. The user wants maximum throughput.

**Why:** Solo dev using agents as a force multiplier. Wall-clock time is determined by the slowest agent in a wave, not total work. More parallel agents = faster delivery.

**How to apply:** Before dispatching work, ask "can any of this run in parallel?" If yes, split it. Don't batch work into one agent just because it's "related" — batch only when there's a genuine sequential dependency or shared context that would be lost.
