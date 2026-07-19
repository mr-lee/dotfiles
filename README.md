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
| `setup-cline-pass-agents.sh` | Credential-free bootstrap for Cline Pass provider config in Pi, Hermes, and opencode |
| `setup-cloud-agent-machine.sh` | Credential-free Ubuntu/Debian cloud dev bootstrap for agents, Tailscale, Mosh, and tmux launchers |
| `setup-tailscale-nat64.sh` | Two-host Tailscale NAT64/DNS64 setup for IPv6-only cloud agents |
| `cloud-agent-doctor` | Public-safe cloud host health check with optional tiny model probes |
| `cloud-agent-update` | Day-2 update helper for dotfiles-managed cloud agent hosts |
| `agent-workspace` | Workspace/scratch/log directory helper and tmux launcher for repos |
| `tmux-agent` | Stable tmux launcher for `pilot`, Codex, Claude, Cline, Cursor, Gemini, Goose, Antigravity, Pi, Hermes, and opencode |

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

## Cloud agent machine

Detailed rebuild steps are in [docs/cloud-agent-runbook.md](docs/cloud-agent-runbook.md).

On a fresh Ubuntu/Debian cloud user:

```bash
GIT_CONFIG_GLOBAL=/dev/null git clone https://github.com/mr-lee/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup-cloud-agent-machine.sh
```

Preview first:

```bash
./setup-cloud-agent-machine.sh --dry-run
```

This installs base dev packages, GitHub CLI, Tailscale/Mosh, Codex, Claude Code, Cline, Cursor Agent, Antigravity CLI, Pi, Hermes, opencode, Cline Pass adapters, a one-week `pass`/GPG cache policy, stable tmux launchers, and cloud helper commands. It does not write credentials.

Credentials stay explicit:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github -C "$(hostname)-github" -N ""
gh auth login --hostname github.com --git-protocol ssh --web
gh ssh-key add ~/.ssh/id_ed25519_github.pub --title "$(hostname)-agent"
gh auth setup-git --hostname github.com
pass insert agents/cline-pass/pi
pass insert agents/cline-pass/hermes
pass insert agents/cline-pass/opencode
codex login
claude auth login
cline auth cline
cursor-agent login
agy
```

If `gh auth login` asks to upload an SSH key, skip that prompt and add
`~/.ssh/id_ed25519_github.pub` with `gh ssh-key add` afterward.

Tailscale login is also explicit:

```bash
sudo tailscale up --hostname <name>
```

For headless agent users, enable systemd lingering so tmux and GPG/pass cache state can survive SSH logout:

```bash
sudo ./setup-cloud-agent-machine.sh --no-system --no-tailscale --no-agents --no-cline-pass --no-tmux-agent --linger-user agentdev
```

Firewall and SSH hardening are opt-in, so a new SSH session is not surprise-locked:

```bash
./setup-cloud-agent-machine.sh --enable-firewall
./setup-cloud-agent-machine.sh --tailscale-only-ssh
./setup-cloud-agent-machine.sh --harden-ssh
```

Stable launchers:

```bash
pilot
codex-tmux
claude-tmux
cline-tmux
cursor-tmux
agy-tmux
pi-tmux
hermes-tmux
opencode-tmux
```

Cloud helpers:

```bash
cloud-agent-doctor          # quick health check
cloud-agent-doctor --full   # includes tiny model probes
cloud-agent-update          # pull dotfiles, refresh tools, run doctor
agent-workspace init
agent-workspace clone <owner/repo>
agent-workspace open <repo> pilot
```

### IPv6-only clients

For an IPv6-only cloud box that needs access to IPv4-only model/auth endpoints,
use a separate IPv4-capable Tailscale node as a NAT64 gateway:

```bash
./setup-tailscale-nat64.sh <gateway-admin-ssh-alias> <client-root-ssh-alias>
```

After the gateway step, approve only the advertised subnet route
`64:ff9b::/96` for the gateway machine in the Tailscale admin console. Do not
enable "use as exit node" unless you intentionally want all client internet
traffic routed through the gateway.

The script configures TAYGA on the gateway, appends the NAT64 route to its
Tailscale advertised routes, disables subnet-route SNAT for this route, enables
route acceptance on the client, and configures DNS64 via `systemd-resolved`.
It does not write credentials.

## Cline Pass agents

To configure Pi, Hermes, and opencode with the same Cline Pass provider setup:

```bash
./setup-cline-pass-agents.sh
```

This configures `cline-pass/glm-5.2` and `cline-pass/kimi-k3`, creates key helper scripts, and installs `hermes-cline` / `opencode-cline` launchers. It does not write credentials.

Credential options:

```bash
# macOS Keychain
security add-generic-password -a "$USER" -s pi-cline-api-key -w '<cline-pass-api-key>' -U
security add-generic-password -a "$USER" -s hermes-cline-api-key -w '<cline-pass-api-key>' -U
security add-generic-password -a "$USER" -s opencode-cline-api-key -w '<cline-pass-api-key>' -U

# Linux pass
pass insert agents/cline-pass/pi
pass insert agents/cline-pass/hermes
pass insert agents/cline-pass/opencode

# or portable shell fallback
export CLINE_API_KEY='<cline-pass-api-key>'
```

Preview first with `./setup-cline-pass-agents.sh --dry-run`.

Use `--pass-prefix <prefix>` if your Linux `pass` entries live somewhere other than `agents/cline-pass`.

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
