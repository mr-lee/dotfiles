# Cloud Agent Machine Runbook

This is a public-safe runbook for rebuilding a cloud development machine for
terminal-based coding agents. It intentionally avoids secrets, OAuth tokens,
private GPG keys, private SSH keys, private hostnames, and exact personal
infrastructure values.

Use placeholders like `<cloud-ip>`, `<tailnet-host>`, `<admin-user>`, and
`<agent-user>`. Keep real credentials in your password manager, `pass`, provider
OAuth flows, or another secret store.

## Target Shape

- Ubuntu/Debian cloud VM
- SSH key access from laptop and phone
- Optional admin user, plus an unprivileged agent user
- Tailscale for stable private connectivity
- Optional UFW firewall and SSH hardening
- `tmux-agent` wrappers for stable long-running agent sessions
- `agent-workspace` conventions for durable repos, scratch work, and logs
- `cloud-agent-doctor` and `cloud-agent-update` for day-2 checks and updates
- Agent CLIs:
  - Codex
  - Claude Code
  - Cline
  - Cursor Agent
  - Antigravity CLI
  - Pi
  - Hermes
  - opencode
- Cline Pass adapters for Pi, Hermes, and opencode
- Optional NAT64/DNS64 for IPv6-only clients that need IPv4-only endpoints

## Local Prerequisites

- SSH keypair created locally and uploaded to the cloud provider during server
  creation
- Public phone SSH key available if phone access is desired
- Local SSH config aliases for the cloud host
- Tailscale account
- Provider accounts for any OAuth-based agents
- A secure place to keep recoverable secrets

Do not commit private keys, provider tokens, OAuth state, `pass` contents, or
machine-specific credentials to this repository.

## 1. Provision The VM

Create a fresh Ubuntu/Debian VM with your cloud provider.

Recommended choices:

- Use provider-side SSH key injection at launch.
- Use a current Ubuntu LTS or Debian stable image.
- Keep at least one tested SSH path open while changing firewall or sshd config.
- If creating an IPv6-only VM, expect some vendor install/auth endpoints to be
  IPv4-only until NAT64/DNS64 is configured.

Record these locally, not in this public repo:

- Public IP or IPv6 address
- Tailscale hostname and IPs after login
- Host key fingerprint
- Admin username
- Agent username

## 2. Set Local SSH Aliases

Add aliases to `~/.ssh/config`. Keep real IPs and usernames local.

Example shape:

```sshconfig
Host cloud-admin
  HostName <cloud-ip-or-tailnet-ip>
  User <admin-user>
  IdentityFile ~/.ssh/<private-key>
  IdentitiesOnly yes
  ServerAliveInterval 30
  ServerAliveCountMax 3

Host cloud-agent
  HostName <cloud-ip-or-tailnet-ip>
  User <agent-user>
  IdentityFile ~/.ssh/<private-key>
  IdentitiesOnly yes
  RequestTTY yes
  ServerAliveInterval 30
  ServerAliveCountMax 3
```

For an IPv6-only host that is not directly reachable from the laptop, bootstrap
through an existing Tailscale-reachable host:

```sshconfig
Host cloud-big-root-bootstrap
  HostName <ipv6-address>
  User root
  IdentityFile ~/.ssh/<private-key>
  ProxyJump cloud-agent-existing
  AddressFamily inet6
```

After Tailscale is up, prefer tailnet aliases over public IP aliases.

## 3. Create Users

The provider image may start with `root` only, or with a default admin user.
Create separate users when needed:

- `<admin-user>`: human admin account with sudo
- `<agent-user>`: daily agent account, usually no passwordless sudo

Example:

```bash
sudo adduser <admin-user>
sudo usermod -aG sudo <admin-user>

sudo adduser <agent-user>
sudo install -d -m 700 -o <agent-user> -g <agent-user> /home/<agent-user>/.ssh
sudo install -m 600 -o <agent-user> -g <agent-user> /tmp/authorized_keys /home/<agent-user>/.ssh/authorized_keys
```

Set and store passwords only where needed. Do not paste passwords into chat,
shell history, repo files, or issue trackers.

## 4. Bootstrap The Agent User

As `<agent-user>`:

```bash
GIT_CONFIG_GLOBAL=/dev/null git clone https://github.com/mr-lee/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup-cloud-agent-machine.sh
```

Useful variants:

```bash
# Preview
./setup-cloud-agent-machine.sh --dry-run

# Bring up Tailscale during bootstrap
./setup-cloud-agent-machine.sh --tailscale-up --tailscale-hostname <tailnet-host>

# Enable linger for long-running tmux/GPG/pass sessions
sudo ./setup-cloud-agent-machine.sh \
  --no-system \
  --no-tailscale \
  --no-agents \
  --no-cline-pass \
  --no-tmux-agent \
  --linger-user <agent-user>
```

The bootstrap script does not write credentials. It installs tooling and prints
the credential/auth steps to run manually.

## 5. Tailscale

Login explicitly:

```bash
sudo tailscale up --hostname <tailnet-host>
```

Then create or update local SSH aliases that use the Tailscale IP or MagicDNS
name.

Verify:

```bash
tailscale status
tailscale ip -4
tailscale ip -6
ssh cloud-agent
```

## 6. Git And GitHub

The cloud bootstrap installs GitHub CLI and configures baseline Git settings:

```bash
git config --global user.name <git-display-name>
git config --global user.email <github-noreply-email>
git config --global init.defaultBranch main
git config --global url.git@github.com:.insteadOf https://github.com/
```

It also writes a managed SSH config block for `github.com` that uses
`~/.ssh/id_ed25519_github`. This key is generated manually in the next step.

Do not copy a laptop GitHub token or laptop SSH private key to the cloud host.
Use a separate SSH key and separate `gh` login per host, so access can be
revoked per machine.

From the agent user on each host:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github -C "$(hostname)-github" -N ""

gh auth login --hostname github.com --git-protocol ssh --web
gh ssh-key add ~/.ssh/id_ed25519_github.pub --title "$(hostname)-agent"
gh auth setup-git --hostname github.com
```

If `gh auth login` asks to upload an SSH key, skip that prompt and add the
managed host key with `gh ssh-key add` afterward.

Verify:

```bash
gh auth status
ssh -T git@github.com
gh repo view <owner>/<repo>
git ls-remote git@github.com:<owner>/<repo>.git HEAD
```

If prompted to trust GitHub's SSH host key, verify the fingerprint against
GitHub's published fingerprints before accepting it.

Permission refinement options:

- Default personal host key: one SSH key and one `gh` login per cloud host. This
  is the simplest useful setup. Revoke by deleting that host's SSH key and
  logging out/revoking the host's GitHub token.
- Repo deploy key: for a sensitive repository, create a separate SSH key and add
  it as a repository deploy key. Use read-only unless that host needs to push to
  that exact repo. This avoids broad account-level Git access but does not cover
  general GitHub API operations.
- Fine-grained token: use for narrow API access to selected repositories. Store
  it in a secret manager, not dotfiles, and prefer environment injection for the
  one command/session that needs it.
- GitHub App or machine account: useful when this becomes shared automation
  rather than personal agent work. Higher setup cost, tighter blast radius.

References:

- GitHub CLI auth: <https://cli.github.com/manual/gh_auth_login>
- Deploy keys: <https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys>
- Fine-grained token permissions: <https://docs.github.com/en/rest/authentication/permissions-required-for-fine-grained-personal-access-tokens>

## 7. Firewall And SSH Hardening

Only do this after:

- admin SSH works
- agent SSH works
- OpenSSH over the Tailscale address works, if you plan to require it
- you have a second active SSH session open for rollback

Options:

```bash
# Public SSH remains allowed; SSH/Mosh over tailscale0 also allowed.
./setup-cloud-agent-machine.sh --enable-firewall

# SSH and Mosh allowed only on tailscale0.
./setup-cloud-agent-machine.sh --tailscale-only-ssh

# Disable password, keyboard-interactive, and root SSH.
./setup-cloud-agent-machine.sh --harden-ssh
```

Avoid disabling the last working admin path. For a new machine, prefer proving
Tailscale access first, then moving to Tailscale-only SSH.

## 8. Secret Store

For Linux hosts, use `pass` for Cline Pass API keys used by Pi, Hermes, and
opencode.

Fresh key path:

```bash
gpg --full-generate-key
gpg --list-secret-keys --keyid-format LONG
pass init <gpg-key-id-or-fingerprint>
```

Restore path:

```bash
gpg --import <private-gpg-key-backup>
pass init <gpg-key-id-or-fingerprint>
git clone <password-store-backup> ~/.password-store
```

Then insert or verify expected entries:

```bash
pass insert agents/cline-pass/pi
pass insert agents/cline-pass/hermes
pass insert agents/cline-pass/opencode

pass show agents/cline-pass/pi >/dev/null
pass show agents/cline-pass/hermes >/dev/null
pass show agents/cline-pass/opencode >/dev/null
```

The bootstrap configures `gpg-agent` so `pass` unlocks cache for one week:

```text
default-cache-ttl 604800
max-cache-ttl 604800
```

That keeps repeated agent use practical without writing raw provider keys to
shell startup files. It also means any process running as the agent user can
decrypt those `pass` entries while the cache is warm, so keep host access
tightly scoped and rotate provider keys if a host is ever suspected compromised.
Override with `./setup-cloud-agent-machine.sh --gpg-cache-ttl <seconds>` if a
shorter cache is preferable for a specific machine.

Keep the private GPG key backup and password store backup outside this public
repo.

Recommended backup pattern:

```bash
mkdir -p ~/secure-backups
chmod 700 ~/secure-backups
gpg --armor --export-secret-keys <gpg-key-id-or-fingerprint> \
  | gpg --symmetric --cipher-algo AES256 \
      -o ~/secure-backups/cloud-agent-pass-gpg-key.asc.gpg
tar -C "$HOME" -cz .password-store \
  | gpg --symmetric --cipher-algo AES256 \
      -o ~/secure-backups/password-store.tar.gz.gpg
```

Store the encrypted GPG-key backup and password-store backup somewhere durable,
such as a password manager attachment, encrypted drive, or other trusted backup
system. Store the symmetric backup passphrase separately. Apple Keychain or a
password manager is appropriate for the passphrase; avoid shell scripts that
push raw private-key material into command arguments or committed files.

Restore check on a disposable host or temporary `GNUPGHOME` before trusting the
backup:

```bash
tmp_gnupg="$(mktemp -d)"
chmod 700 "$tmp_gnupg"
gpg --homedir "$tmp_gnupg" --decrypt ~/secure-backups/cloud-agent-pass-gpg-key.asc.gpg \
  | gpg --homedir "$tmp_gnupg" --import
GNUPGHOME="$tmp_gnupg" gpg --list-secret-keys
rm -rf "$tmp_gnupg"
```

## 9. Agent Authentication

Run OAuth/device-code flows interactively on the remote host:

```bash
codex login
claude auth login
cline auth cline
cursor-agent login
agy
```

Expected verification:

```bash
codex login status
claude auth status --text
cursor-agent status
cline --version
agy --version
```

Some tools do not expose a clean non-interactive status command. For those, use
a tiny prompt probe after login:

```bash
cline --json --thinking none -P cline -t 60 'Reply exactly CLINE_OK'
agy --print 'Reply exactly AGY_OK'
```

## 10. Cline Pass Adapters

The cloud bootstrap calls this by default:

```bash
./setup-cline-pass-agents.sh
```

It configures Pi, Hermes, and opencode to read credentials from `pass` through
helper scripts. It does not store API keys itself.

Smoke tests:

```bash
pi --provider cline-pass --model cline-pass/glm-5.2 --no-tools --no-session -p 'Reply exactly GLM_OK'
hermes --provider cline-pass -m cline-pass/glm-5.2 -z 'Reply exactly GLM_OK'
opencode run -m cline-pass/glm-5.2 'Reply exactly GLM_OK'
```

## 11. tmux Launchers

Use stable wrappers instead of directly starting each tool:

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

These create or attach named tmux sessions, which is useful from both laptop and
phone SSH clients.

## 12. Workspace Conventions

Initialize standard directories:

```bash
agent-workspace init
```

Conventions:

```text
~/workspace/<repo>       durable cloned repositories
~/scratch/<name>         experiments and throwaway work
~/logs/agents            logs and exported agent artifacts
```

Common flows:

```bash
agent-workspace clone <owner/repo>
agent-workspace scratch <name>
agent-workspace open <repo> pilot
agent-workspace open <repo> codex
agent-workspace open <repo> claude
agent-workspace list
```

`agent-workspace open` creates or attaches a repo-specific tmux session with the
working directory set to that repo or scratch directory.

## 13. Phone SSH

Add the phone SSH public key to the agent user's `authorized_keys`.

Verify the public key fingerprint before adding it:

```bash
ssh-keygen -lf <phone-public-key-file>
```

Recommended phone SSH profile:

- host: Tailscale IP or MagicDNS name
- user: `<agent-user>`
- auth: public key
- terminal type: `xterm-256color` if the app's default terminal type is not
  available on the server
- startup command: `pilot` or a specific `*-tmux` wrapper

Do not give the phone admin SSH unless there is a concrete need.

## 14. IPv6-only Client NAT64/DNS64

If a cloud VM has IPv6 only, some provider auth/install/API endpoints may still
be IPv4-only. Use an existing IPv4-capable Tailscale node as a NAT64 gateway:

```bash
./setup-tailscale-nat64.sh <gateway-admin-ssh-alias> <client-root-ssh-alias>
```

After the gateway step, approve only the advertised subnet route in the
Tailscale admin console:

```text
64:ff9b::/96
```

Do not select "use as exit node" unless you intentionally want all client
internet traffic routed through the gateway. The NAT64 route only handles
traffic to synthesized IPv4-only destinations.

Verify from the client:

```bash
ip -6 route get 64:ff9b::0808:0808
getent ahostsv6 api.cline.bot
curl -6 https://api.cline.bot/api/v1/models
```

Expected behavior:

- `64:ff9b::/96` routes through `tailscale0`
- IPv4-only hostnames synthesize `64:ff9b::/96` IPv6 answers
- unauthenticated provider API probes return an HTTP error like `401`, not a
  network connection failure

## 15. Day-2 Operations

Quick health check:

```bash
cloud-agent-doctor
```

Full check with tiny model probes:

```bash
cloud-agent-doctor --full
```

Routine update:

```bash
cloud-agent-update
```

System-inclusive update, which may prompt for sudo:

```bash
cloud-agent-update --system
```

Credential rotation:

- GitHub: remove the old host SSH key in GitHub, generate a new
  `~/.ssh/id_ed25519_github`, run `gh ssh-key add`, then verify with
  `ssh -T git@github.com`.
- Cline Pass keys: rotate provider-side key, update `pass` entries, then run
  `cloud-agent-doctor --full`.
- OAuth tools: use each tool's logout/login flow, then run the smoke tests.
- Tailscale: expire/re-authenticate the device from the admin console or run
  `sudo tailscale up` again when needed.

Host replacement:

1. Provision a fresh VM.
2. Bootstrap dotfiles and Tailscale.
3. Restore or re-create `pass`/GPG.
4. Re-run OAuth and GitHub auth.
5. Run `cloud-agent-doctor --full`.
6. Revoke the old host's Tailscale device, GitHub SSH key, and any host-specific
   provider tokens.

## 16. Final Smoke Test

Run this from the agent user:

```bash
cloud-agent-doctor

codex login status
gh auth status
ssh -T git@github.com
git ls-remote git@github.com:<owner>/<repo>.git HEAD

claude auth status --text
cursor-agent status

pi --provider cline-pass --model cline-pass/glm-5.2 --no-tools --no-session -p 'Reply exactly GLM_OK'
hermes --provider cline-pass -m cline-pass/glm-5.2 -z 'Reply exactly GLM_OK'
opencode run -m cline-pass/glm-5.2 'Reply exactly GLM_OK'

cline --json --thinking none -P cline -t 60 'Reply exactly CLINE_OK'
agy --print 'Reply exactly AGY_OK'
```

Also verify tmux wrappers:

```bash
pilot
codex-tmux
claude-tmux
cline-tmux
cursor-tmux
agy-tmux
```

Detach with the tmux prefix, then `d`.

## 17. Rollback Notes

Firewall:

```bash
sudo ufw status verbose
sudo ufw disable
```

SSH hardening:

```bash
sudo rm -f /etc/ssh/sshd_config.d/99-cloud-agent-hardening.conf
sudo sshd -t
sudo systemctl restart ssh
```

NAT64 gateway:

```bash
sudo tailscale set --advertise-routes=<previous-routes>
sudo systemctl disable --now tayga.service
sudo rm -f /etc/tayga.conf /etc/default/tayga /etc/sysctl.d/99-cloud-nat64.conf
```

NAT64 client:

```bash
sudo tailscale set --accept-routes=false
sudo systemctl disable --now dns64-eth0.service
sudo rm -f /etc/systemd/resolved.conf.d/99-dns64.conf
sudo rm -f /etc/systemd/system/dns64-eth0.service
sudo systemctl daemon-reload
sudo systemctl restart systemd-resolved
```

## Public Repo Checklist

Before committing updates to this runbook or related scripts:

- No private IP addresses unless they are examples from documentation ranges
- No real public IPs
- No real tailnet names
- No private key material
- No OAuth token paths copied with token contents
- No GPG private key IDs tied to a real identity
- No provider account emails
- No secrets in command history snippets
