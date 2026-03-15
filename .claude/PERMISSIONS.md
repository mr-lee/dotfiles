# Claude Code Permissions — Reasoning

Last updated: 2026-03-15

## Philosophy

**Trust by default, guardrail the dangerous.** Rather than allowlisting individual
commands (tedious, incomplete), we allow everything and put `ask` gates on
patterns that are destructive, irreversible, or have a large blast radius.

## Mode

`acceptEdits` — file modifications (Edit/Write) are auto-approved. Combined with
explicit `allow` rules below, this means virtually all normal development work
flows without prompts.

---

## Allow Rules

| Rule | Reasoning |
|------|-----------|
| `Read` | Reading files is always safe — no side effects. |
| `Edit` | Core editing workflow. Covered by `acceptEdits` too, but explicit is clearer. |
| `Write` | File creation. Same rationale as Edit. |
| `Glob` | File search by pattern. Read-only, no risk. Uses ripgrep internally. |
| `Grep` | Content search. Read-only. Uses ripgrep (`rg`) under the hood. |
| `Bash(*)` | Allow all shell commands by default. Dangerous patterns are caught by `ask` rules below (evaluated first). |
| `WebSearch` | Web searches are read-only lookups. No injection surface. |
| `Agent` | Subagents (Explore, Plan, etc.) inherit parent permissions, so the guardrails still apply. |
| `WebFetch(domain:github.com)` | GitHub — repos, issues, APIs. |
| `WebFetch(domain:raw.githubusercontent.com)` | Raw file content from GitHub. |
| `WebFetch(domain:docs.github.com)` | GitHub documentation. |
| `WebFetch(domain:stackoverflow.com)` | Community answers. |
| `WebFetch(domain:developer.mozilla.org)` | MDN Web Docs — HTML/CSS/JS reference. |
| `WebFetch(domain:docs.python.org)` | Python standard library docs. |
| `WebFetch(domain:nodejs.org)` | Node.js documentation. |
| `WebFetch(domain:docs.anthropic.com)` | Anthropic/Claude API docs. |
| `WebFetch(domain:www.npmjs.com)` | npm package info. |
| `WebFetch(domain:pypi.org)` | Python package info. |

### Why not allow all WebFetch?

Arbitrary URL fetching has injection risk — a malicious page could contain prompt
injection payloads. Limiting to known documentation/code domains reduces this
surface significantly.

---

## Ask Rules (prompt before executing)

These are evaluated **before** the `Bash(*)` allow rule, so they act as guardrails.

### Privilege Escalation
| Pattern | Why |
|---------|-----|
| `sudo *` | Any elevated operation should be explicitly approved. |

### Destructive File Operations
| Pattern | Why |
|---------|-----|
| `rm -rf *` | Recursive force-delete. `rm` and `rm -f` (single files) are fine. |
| `rm -fr *` | Same command, alternate flag ordering. |

### Raw Disk / Volume Operations
| Pattern | Why |
|---------|-----|
| `dd *` | Writes raw data to devices/files. Can destroy a disk in one command. |
| `mkfs*` | Formats filesystems. No space before `*` to catch `mkfs.ext4`, `mkfs.apfs`, etc. |
| `diskutil eraseDisk *` | macOS disk erase. |
| `diskutil partitionDisk *` | macOS disk partitioning. |

### Git — Irreversible/Shared-State Operations
| Pattern | Why |
|---------|-----|
| `git push --force*` | Force push overwrites remote history. |
| `git push * --force*` | Catches `--force` appearing after remote/branch args. |
| `git push -f *` | Short flag variant. |
| `git push * -f` | Short flag at end of command. |
| `git reset --hard*` | Discards uncommitted work permanently. |
| `git clean -f*` | Deletes untracked files. |
| `git clean * -f*` | Flag appearing later in args. |

### System Control
| Pattern | Why |
|---------|-----|
| `shutdown *` | System shutdown. |
| `reboot*` | System reboot. No space — `reboot` takes no args on macOS. |
| `halt*` | System halt. |

### Mass Process Termination
| Pattern | Why |
|---------|-----|
| `killall *` | Kills all processes matching a name. |
| `pkill *` | Pattern-based process kill. |

### Recursive Permission/Ownership Changes
| Pattern | Why |
|---------|-----|
| `chmod -R *` | Recursive permission change — large blast radius. |
| `chown -R *` | Recursive ownership change. |

### System Service Management
| Pattern | Why |
|---------|-----|
| `launchctl *` | macOS launch daemon/agent management. |

### Pipe to Shell (Injection Vector)
| Pattern | Why |
|---------|-----|
| `* \| sh` | Piping arbitrary content to a shell. Classic injection vector. |
| `* \| bash` | Same, bash variant. |
| `* \| zsh` | Same, zsh variant. |

### Network Configuration
| Pattern | Why |
|---------|-----|
| `networksetup *` | macOS network configuration. Can change DNS, proxies, etc. |

---

## Not Configured (by design)

| Category | Reasoning |
|----------|-----------|
| **MCP tools** | None configured currently. Will be handled case-by-case as servers are added. |
| **deny rules** | We use `ask` instead of `deny` so commands can still be approved when genuinely needed. Nothing is hard-blocked. |

---

## Maintenance

- Add new `WebFetch` domains as needed for documentation sites you use regularly.
- If a new tool/workflow keeps prompting, add it to `allow`.
- If you notice a dangerous pattern not covered, add it to `ask`.
- Review periodically — permissions should evolve with your workflow.
