# Dotfiles Repository

Personal dotfiles for Matt Lee. Public repo - no work-specific config here.

## Structure

```
.gitconfig         - Git config (personal email, aliases, vimdiff)
.gitignore_global  - Global gitignore (OS, editors, Python, Node, Go, Terraform)
.tmux.conf         - tmux 3.6+ config (vi mode, cross-platform clipboard)
.vimrc             - vim-plug based config (auto-bootstraps plugins)
.zshrc.personal    - Personal zsh config (sourced from ~/.zshrc)
starship.toml      - Starship prompt config
install.sh         - Full setup: symlinks, Starship, zsh plugins, zshrc wiring
setup-cline-pass-agents.sh - Credential-free Cline Pass setup for Pi, Hermes, opencode
setup-cloud-agent-machine.sh - Credential-free Ubuntu/Debian cloud dev bootstrap
setup-tailscale-nat64.sh - Two-host Tailscale NAT64/DNS64 setup for IPv6-only clients
cloud-agent-doctor - Public-safe cloud machine health checks and optional model probes
cloud-agent-update - Day-2 update helper for dotfiles-managed cloud hosts
agent-workspace - Workspace/scratch/log directory helper and repo tmux launcher
tmux-agent        - Stable tmux launcher for pilot/agent sessions
docs/cloud-agent-runbook.md - Public-safe rebuild guide for cloud agent hosts
```

## Install

```bash
./install.sh            # full setup
./install.sh --dry-run  # preview without changes
```

The install script:
1. Symlinks dotfiles into `$HOME`
2. Symlinks `starship.toml` into `~/.config/`
3. Installs Starship via brew if missing
4. Clones zsh-autosuggestions and zsh-syntax-highlighting into `~/.zsh/plugins/`
5. Appends `source ~/.zshrc.personal` to `~/.zshrc` if not already present
6. Prints post-install steps (vim plugins, new shell)

**After install:** Run `vim +PlugInstall +qa`, then open a new shell.

## Conventions

- Files live at the repo root (flat structure, no Stow)
- `install.sh` backs up existing files as `.bak` before overwriting
- Work-specific config (email, GPG signing) goes in `~/.gitconfig.work` (not in this repo) and is loaded via `[include]`
- `.zshrc.personal` is the personal zsh layer - it gets sourced from the system/work `.zshrc`, not the other way around. Never replace `.zshrc` with this file.
- Zsh plugins are git-cloned into `~/.zsh/plugins/` (no framework, no oh-my-zsh)
- `~/.zshrc.local` can be used for machine-specific overrides (sourced last by `.zshrc.personal`, not versioned)
- Cloud networking helpers must stay credential-free and avoid making a gateway an exit node unless explicitly requested.
- Cloud setup docs must stay public-safe: placeholders only for IPs, tailnet names, key fingerprints, account emails, and hostnames.
- Health/update helpers must not print tokens, private keys, `pass` values, OAuth state contents, or real machine inventory in committed examples.

## Making Changes

- Edit files in this repo, then re-run `install.sh` (idempotent - skips already-linked files)
- Keep this repo public - never add secrets, work emails, API keys, or internal tooling references
- Test tmux changes with `tmux source ~/.tmux.conf`
- Test bootstrap scripts with `bash -n` and `--dry-run` when available
- Test vim changes with `:source ~/.vimrc`
- Test prompt changes with `eval "$(starship init zsh)"` or open a new shell
