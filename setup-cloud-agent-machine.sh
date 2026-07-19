#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${HOME}"
PASS_PREFIX="agents/cline-pass"
TAILSCALE_HOSTNAME="${HOSTNAME:-agentdev}"
INSTALL_SYSTEM=true
INSTALL_TAILSCALE=true
TAILSCALE_UP=false
INSTALL_AGENTS=true
CONFIGURE_CLINE_PASS=true
INSTALL_TMUX_AGENT=true
ENABLE_FIREWALL=false
TAILSCALE_ONLY_SSH=false
HARDEN_SSH=false
DRY_RUN=false

usage() {
  cat <<'EOF'
usage: setup-cloud-agent-machine.sh [options]

Credential-free bootstrap for an agentic cloud dev machine.

Defaults:
  - install Ubuntu/Debian base packages when apt/sudo are available
  - install Tailscale and Mosh, but do not run tailscale up unless requested
  - install Codex, Claude Code, Cline, Cursor Agent, Antigravity CLI, Pi, Hermes, and opencode
  - configure Cline Pass adapters for Pi, Hermes, and opencode
  - install tmux-agent wrappers for stable phone/laptop sessions
  - do not enable firewall or rewrite sshd settings unless explicitly requested

Options:
  --target DIR                 Install user files into DIR instead of $HOME
  --pass-prefix PREFIX         pass(1) prefix for Linux secrets (default: agents/cline-pass)
  --tailscale-hostname NAME    Hostname for optional tailscale up
  --tailscale-up               Run sudo tailscale up after installing Tailscale
  --enable-firewall            Enable UFW: deny incoming, allow outgoing, allow public SSH and Tailscale SSH/Mosh
  --tailscale-only-ssh         Enable UFW with SSH/Mosh allowed only on tailscale0
  --harden-ssh                 Disable password/kbd-interactive/root SSH in sshd_config.d
  --no-system                  Skip apt/system package installation
  --no-tailscale               Skip Tailscale installation
  --no-agents                  Skip agent CLI installation
  --no-cline-pass              Skip Cline Pass adapter configuration
  --no-tmux-agent              Skip tmux-agent wrapper installation
  --dry-run                    Print commands without changing the machine
  -h, --help                   Show this help

Post-run auth/credential steps are printed at the end. No API keys, OAuth tokens,
Tailscale auth keys, or model credentials are written by this script.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --pass-prefix)
      PASS_PREFIX="$2"
      shift 2
      ;;
    --tailscale-hostname)
      TAILSCALE_HOSTNAME="$2"
      shift 2
      ;;
    --tailscale-up)
      TAILSCALE_UP=true
      shift
      ;;
    --enable-firewall)
      ENABLE_FIREWALL=true
      shift
      ;;
    --tailscale-only-ssh)
      ENABLE_FIREWALL=true
      TAILSCALE_ONLY_SSH=true
      shift
      ;;
    --harden-ssh)
      HARDEN_SSH=true
      shift
      ;;
    --no-system)
      INSTALL_SYSTEM=false
      shift
      ;;
    --no-tailscale)
      INSTALL_TAILSCALE=false
      shift
      ;;
    --no-agents)
      INSTALL_AGENTS=false
      shift
      ;;
    --no-cline-pass)
      CONFIGURE_CLINE_PASS=false
      shift
      ;;
    --no-tmux-agent)
      INSTALL_TMUX_AGENT=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="${TARGET_DIR}/.local/bin"
SUDO=()
if [[ "${EUID}" -ne 0 ]]; then
  SUDO=(sudo)
fi

run() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
  if [[ "$DRY_RUN" != true ]]; then
    "$@"
  fi
}

run_shell() {
  printf '+ bash -lc %q\n' "$*"
  if [[ "$DRY_RUN" != true ]]; then
    bash -lc "$*"
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

has_apt() {
  need_cmd apt-get
}

node_major() {
  if need_cmd node; then
    node --version | sed -E 's/^v([0-9]+).*/\1/'
  else
    echo 0
  fi
}

ensure_path_block() {
  local file="$1"
  local begin="# >>> cloud-agent-machine path"
  local end="# <<< cloud-agent-machine path"
  local line='export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$HOME/.npm-global/bin:$HOME/.grok/bin:$PATH"'

  if [[ "$DRY_RUN" == true ]]; then
    echo "  ensure PATH block in ${file}"
    return
  fi

  touch "$file"
  if grep -qxF "$begin" "$file"; then
    return
  fi
  {
    printf '\n%s\n' "$begin"
    printf '%s\n' "$line"
    printf '%s\n' "$end"
  } >> "$file"
}

ensure_gpg_tty_block() {
  local file="$1"
  local begin="# >>> cloud-agent-machine gpg tty"
  local end="# <<< cloud-agent-machine gpg tty"

  if [[ "$DRY_RUN" == true ]]; then
    echo "  ensure GPG_TTY block in ${file}"
    return
  fi

  touch "$file"
  if grep -qxF "$begin" "$file"; then
    return
  fi
  {
    printf '\n%s\n' "$begin"
    printf '%s\n' 'if command -v gpg-connect-agent >/dev/null 2>&1 && [ -t 0 ]; then'
    printf '%s\n' '  export GPG_TTY="$(tty)"'
    printf '%s\n' '  gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true'
    printf '%s\n' 'fi'
    printf '%s\n' "$end"
  } >> "$file"
}

install_system_packages() {
  if ! has_apt; then
    echo "  skip system packages: apt-get not found"
    return
  fi

  run "${SUDO[@]}" apt-get update
  run "${SUDO[@]}" apt-get install -y \
    build-essential ca-certificates curl dbus-x11 fail2ban git gnupg jq \
    libsecret-1-0 libsecret-tools mosh pass pipx python3 python3-yaml ripgrep \
    tmux ufw unzip xz-utils

  if ! need_cmd fd && need_cmd fdfind && [[ ! -e "${LOCAL_BIN}/fd" ]]; then
    run mkdir -p "$LOCAL_BIN"
    run ln -s "$(command -v fdfind)" "${LOCAL_BIN}/fd"
  fi

  if [[ "$(node_major)" -lt 22 ]]; then
    run_shell 'curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/nodesource.gpg'
    run_shell 'echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null'
    run "${SUDO[@]}" apt-get update
    run "${SUDO[@]}" apt-get install -y nodejs
  fi
}

install_tailscale() {
  if need_cmd tailscale; then
    echo "  ok  tailscale already installed"
  else
    run_shell 'curl -fsSL https://tailscale.com/install.sh | sh'
  fi

  if [[ "$TAILSCALE_UP" == true ]]; then
    run "${SUDO[@]}" tailscale up --hostname "$TAILSCALE_HOSTNAME"
  fi
}

install_agents() {
  run mkdir -p "$LOCAL_BIN"
  export PATH="${LOCAL_BIN}:${TARGET_DIR}/.opencode/bin:${TARGET_DIR}/.npm-global/bin:${TARGET_DIR}/.grok/bin:${PATH}"

  ensure_path_block "${TARGET_DIR}/.profile"
  ensure_gpg_tty_block "${TARGET_DIR}/.profile"
  if [[ -e "${TARGET_DIR}/.bashrc" || ! -e "${TARGET_DIR}/.zshrc" ]]; then
    ensure_path_block "${TARGET_DIR}/.bashrc"
    ensure_gpg_tty_block "${TARGET_DIR}/.bashrc"
  fi

  if need_cmd npm; then
    run npm config set prefix "$TARGET_DIR/.local"
    run npm install -g @openai/codex @anthropic-ai/claude-code cline opencode-ai
    run npm install -g @earendil-works/pi-coding-agent --ignore-scripts
  else
    echo "  WARN  npm missing; skipping Codex/Claude/Cline/Pi/opencode installs" >&2
  fi

  if ! need_cmd cursor-agent; then
    run_shell 'curl -fsSL https://cursor.com/install -o /tmp/cursor-agent-install.sh && bash /tmp/cursor-agent-install.sh'
  else
    echo "  ok  cursor-agent already installed"
  fi

  if ! need_cmd uv; then
    run_shell 'curl -LsSf https://astral.sh/uv/install.sh | sh'
    export PATH="${LOCAL_BIN}:${HOME}/.cargo/bin:${PATH}"
  fi

  if need_cmd uv && need_cmd pipx; then
    run uv python install 3.11
    local python311
    if [[ "$DRY_RUN" == true ]]; then
      python311="<uv-python-3.11>"
    else
      python311="$(uv python find 3.11)"
    fi
    if [[ "$DRY_RUN" == true ]]; then
      run pipx install --python "$python311" hermes-agent
    elif pipx list 2>/dev/null | grep -q 'package hermes-agent'; then
      run pipx upgrade hermes-agent
    else
      run pipx install --python "$python311" hermes-agent
    fi
  else
    echo "  WARN  uv or pipx missing; skipping Hermes install" >&2
  fi

  if ! need_cmd agy; then
    run_shell 'curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir "$HOME/.local/bin"'
  else
    echo "  ok  agy already installed"
  fi
}

configure_cline_pass() {
  local setup="${SCRIPT_DIR}/setup-cline-pass-agents.sh"
  if [[ ! -x "$setup" ]]; then
    echo "  WARN  setup-cline-pass-agents.sh not found or not executable; skipping" >&2
    return
  fi

  run "$setup" --target "$TARGET_DIR" --pass-prefix "$PASS_PREFIX"
}

install_tmux_agent() {
  local source="${SCRIPT_DIR}/tmux-agent"
  if [[ ! -f "$source" ]]; then
    echo "  WARN  tmux-agent not found next to setup script; skipping" >&2
    return
  fi

  run mkdir -p "$LOCAL_BIN"
  run install -m 755 "$source" "${LOCAL_BIN}/tmux-agent"
  local name
  for name in pilot codex-tmux claude-tmux cline-tmux cursor-tmux agy-tmux antigravity-tmux pi-tmux hermes-tmux opencode-tmux; do
    run ln -sfn tmux-agent "${LOCAL_BIN}/${name}"
  done
}

enable_firewall() {
  if ! need_cmd ufw; then
    echo "  skip firewall: ufw not found"
    return
  fi

  run "${SUDO[@]}" ufw default deny incoming
  run "${SUDO[@]}" ufw default allow outgoing
  if [[ "$TAILSCALE_ONLY_SSH" != true ]]; then
    run "${SUDO[@]}" ufw allow 22/tcp comment "SSH key auth"
  fi
  run "${SUDO[@]}" ufw allow in on tailscale0 to any port 22 proto tcp comment "SSH over Tailscale"
  run "${SUDO[@]}" ufw allow in on tailscale0 to any port 60000:61000 proto udp comment "Mosh over Tailscale"
  run "${SUDO[@]}" ufw --force enable
}

harden_ssh() {
  local conf="/etc/ssh/sshd_config.d/99-cloud-agent-hardening.conf"
  local body='PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
X11Forwarding no
'

  if [[ "$DRY_RUN" == true ]]; then
    echo "  write ${conf}"
    echo "  restart ssh"
    return
  fi

  printf '%s' "$body" | "${SUDO[@]}" tee "$conf" >/dev/null
  "${SUDO[@]}" sshd -t
  "${SUDO[@]}" systemctl restart ssh
}

print_summary() {
  cat <<EOF

Done.

Credential setup is intentionally separate.

Linux pass setup:
  gpg --full-generate-key
  gpg --list-secret-keys --keyid-format LONG
  pass init <gpg-key-id-or-fingerprint>
  pass insert ${PASS_PREFIX}/pi
  pass insert ${PASS_PREFIX}/hermes
  pass insert ${PASS_PREFIX}/opencode

Interactive auth:
  codex login
  claude auth login
  cline auth cline
  cursor-agent login
  agy

Tailscale:
  sudo tailscale up --hostname ${TAILSCALE_HOSTNAME}

Recommended verification:
  codex login status
  claude auth status --text
  cline version
  cursor-agent status
  agy --version
  pi --version
  hermes --version
  opencode --version
  tmux-agent --help

Stable tmux launchers:
  pilot
  codex-tmux
  claude-tmux
  cline-tmux
  cursor-tmux
  agy-tmux
  pi-tmux
  hermes-tmux
  opencode-tmux

Firewall/SSH hardening is opt-in:
  ./setup-cloud-agent-machine.sh --enable-firewall
  ./setup-cloud-agent-machine.sh --tailscale-only-ssh
  ./setup-cloud-agent-machine.sh --harden-ssh
EOF
}

echo "Cloud agent machine setup -> ${TARGET_DIR}"
if [[ "$DRY_RUN" == true ]]; then
  echo "(dry run - no changes will be made)"
fi
echo

if [[ "$INSTALL_SYSTEM" == true ]]; then
  echo "System packages"
  install_system_packages
fi

if [[ "$INSTALL_TAILSCALE" == true ]]; then
  echo
  echo "Tailscale"
  install_tailscale
fi

if [[ "$INSTALL_AGENTS" == true ]]; then
  echo
  echo "Agent CLIs"
  install_agents
fi

if [[ "$CONFIGURE_CLINE_PASS" == true ]]; then
  echo
  echo "Cline Pass adapters"
  configure_cline_pass
fi

if [[ "$INSTALL_TMUX_AGENT" == true ]]; then
  echo
  echo "tmux-agent"
  install_tmux_agent
fi

if [[ "$ENABLE_FIREWALL" == true ]]; then
  echo
  echo "Firewall"
  enable_firewall
fi

if [[ "$HARDEN_SSH" == true ]]; then
  echo
  echo "SSH hardening"
  harden_ssh
fi

print_summary
