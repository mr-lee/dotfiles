# Dotfiles Repository

Personal dotfiles for Matt Lee. Public repo - no work-specific config here.

## Structure

```
.gitconfig         - Git config (personal email, aliases, vimdiff)
.gitignore_global  - Global gitignore (OS, editors, Python, Node, Go, Terraform)
.tmux.conf         - tmux 3.6+ config (vi mode, cross-platform clipboard)
.vimrc             - vim-plug based config (auto-bootstraps plugins)
.zshrc             - zsh config (not yet modernized)
.mrlee.zsh-theme   - oh-my-zsh theme (not yet modernized)
install.sh         - Symlinks dotfiles into $HOME (--dry-run to preview)
```

## Install

```bash
./install.sh            # symlink everything
./install.sh --dry-run  # preview without changes
```

After install, run `vim +PlugInstall +qa` to bootstrap vim plugins.

## Conventions

- Files live at the repo root (flat structure, no Stow)
- `install.sh` backs up existing files as `.bak` before overwriting
- Work-specific config (email, GPG signing) goes in `~/.gitconfig.work` (not in this repo) and is loaded via `[include]`
- `.zshrc` and `.mrlee.zsh-theme` are skipped by install.sh - they need manual setup since zsh config is often managed by other tools

## Making Changes

- Edit files in this repo, then re-run `install.sh` (idempotent - skips already-linked files)
- Keep this repo public - never add secrets, work emails, API keys, or internal tooling references
- Test tmux changes with `tmux source ~/.tmux.conf`
- Test vim changes with `:source ~/.vimrc`
