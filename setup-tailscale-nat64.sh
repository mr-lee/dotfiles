#!/usr/bin/env bash
set -euo pipefail

GATEWAY_HOST=""
CLIENT_HOST=""
NAT64_PREFIX="64:ff9b::/96"
TAYGA_POOL="192.168.255.0/24"
TAYGA_IPV4="192.168.255.1"
TAYGA_IPV6="fd00:64::1"
TUN_DEV="nat64"
GATEWAY_OUT_IF="eth0"
GATEWAY_TS_IF="tailscale0"
CLIENT_DNS_IF="eth0"
DNS64_SERVERS=("2001:4860:4860::6464" "2001:4860:4860::64")
SKIP_APPROVAL_PROMPT=false
SKIP_CLIENT=false
SKIP_VERIFY=false
DRY_RUN=false

usage() {
  cat <<'EOF'
usage: setup-tailscale-nat64.sh [options] <gateway-ssh-host> <client-ssh-host>

Set up IPv4-only egress for an IPv6-only Tailscale node without making the
gateway an exit node.

Example:
  ./setup-tailscale-nat64.sh hadmin-ts hbig-root-ts

The gateway host should be an SSH alias/user with sudo. The client host should
be root or sudo-capable. The script does not write credentials.

What it configures:
  gateway:
    - installs and configures TAYGA for 64:ff9b::/96 NAT64
    - enables IPv4/IPv6 forwarding
    - allows only the NAT64 routed path through UFW, if UFW is active
    - appends 64:ff9b::/96 to Tailscale advertised routes
    - disables Tailscale subnet-route SNAT for this NAT64 use case
  client:
    - accepts Tailscale routes
    - configures Google DNS64 through systemd-resolved
    - verifies IPv4-only hostnames resolve to 64:ff9b::/96

Options:
  --prefix PREFIX              NAT64 prefix (default: 64:ff9b::/96)
  --pool CIDR                  TAYGA private IPv4 pool (default: 192.168.255.0/24)
  --tayga-ipv4 ADDR            TAYGA IPv4 address (default: 192.168.255.1)
  --tayga-ipv6 ADDR            TAYGA IPv6 address (default: fd00:64::1)
  --tun DEV                    TAYGA tunnel device (default: nat64)
  --gateway-out-if IFACE       Gateway IPv4 egress interface (default: eth0)
  --gateway-ts-if IFACE        Gateway Tailscale interface (default: tailscale0)
  --client-dns-if IFACE        Client DNS link interface (default: eth0)
  --dns64 SERVER[,SERVER]      DNS64 server list
                               (default: 2001:4860:4860::6464,2001:4860:4860::64)
  --skip-approval-prompt       Do not pause for Tailscale route approval
  --skip-client                Configure only the gateway
  --skip-verify                Skip endpoint verification
  --dry-run                    Print planned actions without changing hosts
  -h, --help                   Show this help

Manual approval:
  After gateway setup, approve the advertised 64:ff9b::/96 subnet route for the
  gateway machine in the Tailscale admin console. Do not enable "use as exit
  node" unless you intentionally want all client internet traffic routed through
  the gateway.

Rollback:
  gateway:
    sudo tailscale set --advertise-routes=<your-non-nat64-routes>
    sudo systemctl disable --now tayga.service
    sudo rm -f /etc/tayga.conf /etc/default/tayga /etc/sysctl.d/99-cloud-nat64.conf
  client:
    sudo tailscale set --accept-routes=false
    sudo systemctl disable --now dns64-eth0.service
    sudo rm -f /etc/systemd/resolved.conf.d/99-dns64.conf /etc/systemd/system/dns64-eth0.service
    sudo systemctl restart systemd-resolved
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

join_by() {
  local sep="$1"
  shift
  local first=true
  local item
  for item in "$@"; do
    if [[ "$first" == true ]]; then
      first=false
    else
      printf '%s' "$sep"
    fi
    printf '%s' "$item"
  done
}

split_csv() {
  local value="$1"
  IFS=',' read -r -a DNS64_SERVERS <<< "$value"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      NAT64_PREFIX="$2"
      shift 2
      ;;
    --pool)
      TAYGA_POOL="$2"
      shift 2
      ;;
    --tayga-ipv4)
      TAYGA_IPV4="$2"
      shift 2
      ;;
    --tayga-ipv6)
      TAYGA_IPV6="$2"
      shift 2
      ;;
    --tun)
      TUN_DEV="$2"
      shift 2
      ;;
    --gateway-out-if)
      GATEWAY_OUT_IF="$2"
      shift 2
      ;;
    --gateway-ts-if)
      GATEWAY_TS_IF="$2"
      shift 2
      ;;
    --client-dns-if)
      CLIENT_DNS_IF="$2"
      shift 2
      ;;
    --dns64)
      split_csv "$2"
      shift 2
      ;;
    --skip-approval-prompt)
      SKIP_APPROVAL_PROMPT=true
      shift
      ;;
    --skip-client)
      SKIP_CLIENT=true
      shift
      ;;
    --skip-verify)
      SKIP_VERIFY=true
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
    --*)
      die "unknown option: $1"
      ;;
    *)
      if [[ -z "$GATEWAY_HOST" ]]; then
        GATEWAY_HOST="$1"
      elif [[ -z "$CLIENT_HOST" ]]; then
        CLIENT_HOST="$1"
      else
        die "unexpected extra argument: $1"
      fi
      shift
      ;;
  esac
done

[[ -n "$GATEWAY_HOST" ]] || die "missing gateway SSH host"
if [[ "$SKIP_CLIENT" != true ]]; then
  [[ -n "$CLIENT_HOST" ]] || die "missing client SSH host"
fi

DNS64_JOINED="$(join_by ' ' "${DNS64_SERVERS[@]}")"

run() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
  if [[ "$DRY_RUN" != true ]]; then
    "$@"
  fi
}

ssh_cmd() {
  local host="$1"
  shift
  run ssh "$host" "$@"
}

stage_script() {
  local host="$1"
  local remote_path="$2"
  local local_path="$3"

  if [[ "$DRY_RUN" == true ]]; then
    echo "  stage ${local_path} -> ${host}:${remote_path}"
    return
  fi

  scp "$local_path" "${host}:${remote_path}" >/dev/null
  ssh "$host" "chmod 0755 '$remote_path'"
}

make_gateway_script() {
  local path="$1"
  cat > "$path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

NAT64_PREFIX="${NAT64_PREFIX:?}"
TAYGA_POOL="${TAYGA_POOL:?}"
TAYGA_IPV4="${TAYGA_IPV4:?}"
TAYGA_IPV6="${TAYGA_IPV6:?}"
TUN_DEV="${TUN_DEV:?}"
OUT_IF="${OUT_IF:?}"
TS_IF="${TS_IF:?}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root, for example: sudo bash $0" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y tayga iptables jq

install -d -m 0755 /var/lib/tayga

cat >/etc/tayga.conf <<CFG
tun-device ${TUN_DEV}
ipv4-addr ${TAYGA_IPV4}
ipv6-addr ${TAYGA_IPV6}
prefix ${NAT64_PREFIX}
dynamic-pool ${TAYGA_POOL}
data-dir /var/lib/tayga
CFG

cat >/etc/default/tayga <<CFG
CONFIGURE_IFACE="yes"
CONFIGURE_NAT44="yes"
DAEMON_OPTS=""
IPV4_TUN_ADDR="${TAYGA_IPV4}/24"
IPV6_TUN_ADDR="${TAYGA_IPV6}/128"
CFG

cat >/etc/sysctl.d/99-cloud-nat64.conf <<CFG
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
CFG
sysctl --system >/dev/null

systemctl disable --now cloud-nat64-tayga.service >/dev/null 2>&1 || true
rm -f /etc/systemd/system/cloud-nat64-tayga.service
systemctl daemon-reload
ip link delete "${TUN_DEV}" >/dev/null 2>&1 || true

if iptables -t nat -C POSTROUTING -s "${TAYGA_POOL}" -o "${OUT_IF}" -j MASQUERADE 2>/dev/null; then
  iptables -t nat -D POSTROUTING -s "${TAYGA_POOL}" -o "${OUT_IF}" -j MASQUERADE
fi

if command -v ufw >/dev/null 2>&1 && ufw status | grep -q '^Status: active'; then
  ensure_ufw_route() {
    local comment="$1"
    shift
    if ! ufw status verbose | grep -Fq "${comment}"; then
      ufw route allow "$@" comment "${comment}"
    fi
  }

  ensure_ufw_route "NAT64 v6 from Tailscale" in on "${TS_IF}" out on "${TUN_DEV}" to "${NAT64_PREFIX}"
  ensure_ufw_route "NAT64 v4 egress" in on "${TUN_DEV}" out on "${OUT_IF}" from "${TAYGA_POOL}"
  ensure_ufw_route "NAT64 v4 return" in on "${OUT_IF}" out on "${TUN_DEV}" to "${TAYGA_POOL}"
  ensure_ufw_route "NAT64 v6 return" in on "${TUN_DEV}" out on "${TS_IF}" from "${NAT64_PREFIX}"
fi

systemctl enable --now tayga.service

mapfile -t advertised_routes < <(tailscale debug prefs | jq -r '.AdvertiseRoutes[]?')
route_seen=false
for route in "${advertised_routes[@]}"; do
  if [[ "$route" == "$NAT64_PREFIX" ]]; then
    route_seen=true
    break
  fi
done
if [[ "$route_seen" != true ]]; then
  advertised_routes+=("$NAT64_PREFIX")
fi
advertise_arg="$(IFS=,; printf '%s' "${advertised_routes[*]}")"
tailscale set --advertise-routes="${advertise_arg}" --snat-subnet-routes=false

echo
echo "tayga.service: $(systemctl is-active tayga.service)"
ip link show "${TUN_DEV}"
ip -6 route show "${NAT64_PREFIX}"
iptables -t nat -S POSTROUTING | grep -E 'tayga|192\.168\.255' || true
tailscale debug prefs | grep -E 'AdvertiseRoutes|NoSNAT|RouteAll|ExitNode' -A4 -B1 || true
echo
echo "Approve ${NAT64_PREFIX} for this gateway in the Tailscale admin console if needed."
EOF
}

make_client_script() {
  local path="$1"
  cat > "$path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

CLIENT_DNS_IF="${CLIENT_DNS_IF:?}"
DNS64_SERVERS="${DNS64_SERVERS:?}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root, for example: sudo bash $0" >&2
  exit 1
fi

tailscale set --accept-routes=true

install -d -m 0755 /etc/systemd/resolved.conf.d
cat >/etc/systemd/resolved.conf.d/99-dns64.conf <<CFG
[Resolve]
DNS=${DNS64_SERVERS}
Domains=~.
CFG

cat >/etc/systemd/system/dns64-eth0.service <<CFG
[Unit]
Description=Apply DNS64 resolver settings to ${CLIENT_DNS_IF}
After=systemd-resolved.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/resolvectl dns ${CLIENT_DNS_IF} ${DNS64_SERVERS}
ExecStart=/usr/bin/resolvectl domain ${CLIENT_DNS_IF} ~.
ExecStart=/usr/bin/resolvectl default-route ${CLIENT_DNS_IF} yes
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
CFG

systemctl daemon-reload
systemctl restart systemd-resolved
systemctl enable --now dns64-eth0.service
resolvectl flush-caches || true

echo
echo "tailscale accept-routes:"
tailscale debug prefs | grep -E 'RouteAll|ExitNode|AdvertiseRoutes' -A4 -B1 || true
echo
echo "DNS64:"
resolvectl status | sed -n '1,120p'
echo
echo "NAT64 route:"
ip -6 route get 64:ff9b::0808:0808 || true
EOF
}

verify_client() {
  if [[ "$SKIP_VERIFY" == true || "$SKIP_CLIENT" == true ]]; then
    return
  fi

  echo
  echo "Verification"
  ssh_cmd "$CLIENT_HOST" "set -eu
resolvectl query api.cline.bot || true
getent ahostsv6 api.cline.bot || true
curl -6 -sS --connect-timeout 8 --max-time 20 https://api.cline.bot/api/v1/models -o /tmp/dns64-cline-probe.out -w 'cline_api_http=%{http_code} remote=%{remote_ip} local=%{local_ip}\n' || true
head -c 160 /tmp/dns64-cline-probe.out 2>/dev/null || true
printf '\n'"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

gateway_script="${tmpdir}/setup-nat64-gateway.sh"
client_script="${tmpdir}/setup-nat64-client.sh"
make_gateway_script "$gateway_script"
make_client_script "$client_script"

echo "Gateway NAT64 -> ${GATEWAY_HOST}"
remote_gateway="/tmp/setup-nat64-gateway-$$.sh"
stage_script "$GATEWAY_HOST" "$remote_gateway" "$gateway_script"
if [[ "$DRY_RUN" == true ]]; then
  echo "  run sudo gateway setup on ${GATEWAY_HOST}"
else
  ssh -tt "$GATEWAY_HOST" \
    "sudo env NAT64_PREFIX='${NAT64_PREFIX}' TAYGA_POOL='${TAYGA_POOL}' TAYGA_IPV4='${TAYGA_IPV4}' TAYGA_IPV6='${TAYGA_IPV6}' TUN_DEV='${TUN_DEV}' OUT_IF='${GATEWAY_OUT_IF}' TS_IF='${GATEWAY_TS_IF}' bash '${remote_gateway}'"
fi

if [[ "$SKIP_APPROVAL_PROMPT" != true && "$SKIP_CLIENT" != true ]]; then
  cat <<EOF

Approve ${NAT64_PREFIX} for ${GATEWAY_HOST} in the Tailscale admin console now.
Do not select "use as exit node" unless you want all client internet traffic
routed through the gateway.
EOF
  read -r -p "Press Enter after route approval, or Ctrl-C to stop before client setup. "
fi

if [[ "$SKIP_CLIENT" != true ]]; then
  echo
  echo "Client DNS64/route acceptance -> ${CLIENT_HOST}"
  remote_client="/tmp/setup-nat64-client-$$.sh"
  stage_script "$CLIENT_HOST" "$remote_client" "$client_script"
  if [[ "$DRY_RUN" == true ]]; then
    echo "  run sudo client setup on ${CLIENT_HOST}"
  else
    ssh -tt "$CLIENT_HOST" \
      "sudo env CLIENT_DNS_IF='${CLIENT_DNS_IF}' DNS64_SERVERS='${DNS64_JOINED}' bash '${remote_client}'"
  fi
fi

verify_client

cat <<EOF

Done.

Useful smoke tests on the client:
  curl -6 https://api.cline.bot/api/v1/models
  pi --provider cline-pass --model cline-pass/glm-5.2 --no-tools --no-session -p 'Reply exactly GLM_OK'
  hermes --provider cline-pass -m cline-pass/glm-5.2 -z 'Reply exactly GLM_OK'
  opencode run -m cline-pass/glm-5.2 'Reply exactly GLM_OK'
EOF
