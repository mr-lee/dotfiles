---
name: Always push after committing/merging
description: Single-dev project — push to origin immediately after every commit or merge, don't accumulate local commits.
type: feedback
---

This is a single-developer project. Always `git push` immediately after committing or merging work. Don't let local commits accumulate.

**Why:** No risk of conflicts from other developers, and keeping origin up to date means work is backed up and CI runs sooner.

**How to apply:** After every `git commit` or `git merge --squash` + commit, follow up with `git push`.
