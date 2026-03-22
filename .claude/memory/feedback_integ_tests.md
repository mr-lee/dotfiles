---
name: Always write integration tests, not just unit tests
description: Every agent must write integration tests in addition to unit tests. Test real flows end-to-end.
type: feedback
---

Every agent that writes code MUST write integration tests in addition to unit tests. Unit tests alone are insufficient — they test components in isolation but miss the wiring between them.

**Why:** Unit tests with mocks can pass while the real integration is broken. Integration tests catch the actual behavior.

**How to apply:**
- Unit tests: test individual functions/classes with mocks (already doing this)
- Integration tests: test real flows end-to-end with real (or in-memory) dependencies wired together
- Put integration tests in `test/integration/` or the framework's convention for integration tests
- Include this requirement in every agent prompt: "Write both unit tests AND integration tests"
