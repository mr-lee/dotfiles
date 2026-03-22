# dotfiles

Personal dotfiles for macOS/Linux. Managed with symlinks, no framework.

## What's in here

| File | What it does |
|------|-------------|
| `.gitconfig` | Git aliases (`lg`, `co`, `ci`, `df`), vimdiff, SSH URL rewrite. Personal email by default - work config loaded from `~/.gitconfig.work` if present. |
| `.gitignore_global` | Global ignores for OS files, editors, Python, Node, Go, Terraform |
| `.tmux.conf` | tmux 3.6+. Vi copy mode, cross-platform clipboard (macOS/Linux), mouse, intuitive splits |
| `.vimrc` | vim-plug (auto-bootstraps). fzf, fugitive, undotree, surround, commentary, lightline. Space leader. |
| `.zshrc.personal` | Personal zsh layer - sourced from your system `.zshrc`, doesn't replace it |
| `starship.toml` | [Starship](https://starship.rs) prompt config |

## Install

```bash
git clone git@github.com:mr-lee/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

This will:
- Symlink dotfiles into `$HOME` (backs up existing files as `.bak`)
- Install [Starship](https://starship.rs) via brew if missing
- Clone zsh-autosuggestions and zsh-syntax-highlighting
- Append `source ~/.zshrc.personal` to your `.zshrc`

Preview first with `./install.sh --dry-run`.

### Post-install

```bash
vim +PlugInstall +qa   # bootstrap vim plugins
```

Then open a new shell.

## Work config

Work-specific git config (email, GPG signing) lives in `~/.gitconfig.work`, which is **not** in this repo. It gets loaded automatically via `[include]`.

Machine-specific zsh overrides go in `~/.zshrc.local` (also not in this repo, sourced last).

## Updating

Edit files in this repo, commit, push. Re-run `./install.sh` if you added new files (it's idempotent).
