# Memory Index

## User profile (general, cross-project)
- [user_profile.md](user_profile.md) — GitHub username mr-lee, SSH access, agent scaffolding preferences
- [feedback_work_style.md](feedback_work_style.md) — Solo dev with massive agent parallelism, research-first, spec precisely, retros mandatory

## General working preferences (apply to ALL projects)
- [feedback_never_defer_work.md](feedback_never_defer_work.md) — Fix issues immediately, never suggest "save for next session"
- [feedback_proactive_memories.md](feedback_proactive_memories.md) — Save feedback/learnings immediately, don't wait to be asked
- [feedback_automate_first.md](feedback_automate_first.md) — Always script/automate before asking user to do manual UI steps
- [feedback_integ_tests.md](feedback_integ_tests.md) — Always write integration tests, not just unit tests
- [feedback_always_delegate.md](feedback_always_delegate.md) — Never do implementation work inline; always dispatch subagents
- [feedback_never_foreground_agents.md](feedback_never_foreground_agents.md) — NEVER launch foreground agents; always run_in_background: true
- [feedback_background_agents_only.md](feedback_background_agents_only.md) — All subagents must run in background, never block conversation
- [feedback_maximize_parallelism.md](feedback_maximize_parallelism.md) — Maximize parallel agents; parallelize across domains, serialize within
- [feedback_redispatch_not_self_fix.md](feedback_redispatch_not_self_fix.md) — On agent failure, re-dispatch a new agent instead of doing the work yourself
- [feedback_andon_cord.md](feedback_andon_cord.md) — Subagents must escalate uncertainty, not guess
- [feedback_squash_merge.md](feedback_squash_merge.md) — Always squash merge worktree branches into main, clean linear history
- [feedback_wave_completion_pipeline.md](feedback_wave_completion_pipeline.md) — Auto-dispatch retro synthesis + security review + code quality review after every wave
- [feedback_fine_grained_agents.md](feedback_fine_grained_agents.md) — Break tasks into single-file/single-concern agents; broad tasks cause context exhaustion
- [feedback_orchestrator_reads_guide.md](feedback_orchestrator_reads_guide.md) — Orchestrator must read docs/orchestrator-guide.md on first turn and after compaction
- [feedback_commit_and_push.md](feedback_commit_and_push.md) — Single-dev project: always push immediately after commit/merge
- [feedback_keep_going.md](feedback_keep_going.md) — Don't wait for permission to dispatch planned waves; keep going, use andon cord only for real blockers
- [feedback_use_haiku_for_specced_tasks.md](feedback_use_haiku_for_specced_tasks.md) — Use haiku for clearly-specced single-file tasks; default cheap, upgrade only when needed
- [feedback_quality_by_model.md](feedback_quality_by_model.md) — Post-wave reviews must tag quality scores by model to evaluate cost vs quality tradeoffs
- [feedback_agent_self_manage.md](feedback_agent_self_manage.md) — Subagents must commit their own work and update the backlog themselves
- [feedback_never_delete_move_instead.md](feedback_never_delete_move_instead.md) — Never delete data, move it instead; preserve content when reorganizing
