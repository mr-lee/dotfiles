---
name: Standard wave completion pipeline — automated post-wave agents
description: After every wave merge, automatically dispatch retro synthesis, security review, and code quality review agents. Don't do these manually.
type: feedback
---

After EVERY wave merges, the orchestrator MUST automatically dispatch these post-wave agents (all background, all parallel):

1. **Retro synthesis agent** — reads all retros from the wave, synthesizes patterns, proposes AGENTS.md edits
2. **Security review agent** — reviews all new/changed code from the wave, writes findings to `docs/reviews/`
3. **Code quality review agent** — reviews all new/changed code, writes findings to `docs/reviews/`

Then, if findings have Critical or High issues:
4. **Fix agents** — dispatched in parallel (one for security, one for code quality) to address findings

This is a STANDARD PIPELINE, not something the orchestrator does manually or decides to do case-by-case. It happens after every wave, automatically, without the user asking.

**Why:** These reviews should be automatic. Making them automatic ensures consistent quality gates and process improvement.

**How to apply:** After the merge agent for a wave completes, immediately dispatch the three review agents in a single message. Don't wait for the user to ask.
