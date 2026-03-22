---
name: Automate first — never make the user do manual work that can be scripted
description: Always check for CLI/API automation before walking the user through manual UI steps. Script it.
type: feedback
---

NEVER walk the user through manual UI steps (web consoles, GUIs, etc.) when there's a CLI or API that can do the same thing. Always research automation options FIRST.

**Why:** Walking through manual console clicking when a CLI could do it automatically wastes the user's time and attention on something an agent could have scripted.

**How to apply:** Before any manual walkthrough, ask: "Can this be scripted?" If yes, script it. If partially, script what you can and only ask the user for the truly manual parts. Dispatch a background agent to research CLI options if unsure. The user's time is the most expensive resource — protect it.
