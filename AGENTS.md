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

## Making Changes

- Edit files in this repo, then re-run `install.sh` (idempotent - skips already-linked files)
- Keep this repo public - never add secrets, work emails, API keys, or internal tooling references
- Test tmux changes with `tmux source ~/.tmux.conf`
- Test vim changes with `:source ~/.vimrc`
- Test prompt changes with `eval "$(starship init zsh)"` or open a new shell
