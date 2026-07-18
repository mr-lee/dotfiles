#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${HOME}"
DRY_RUN=false
SET_DEFAULTS=true
WRAP_DEFAULT_BINARIES=true
PASS_PREFIX="agents/cline-pass"

CLINE_PASS_BASE_URL="https://api.cline.bot/api/v1"
GLM_MODEL="cline-pass/glm-5.2"
KIMI_MODEL="cline-pass/kimi-k3"
CONTEXT_WINDOW=1048576
MAX_TOKENS=131072

usage() {
    cat <<'EOF'
Usage: setup-cline-pass-agents.sh [options]

Configures Cline Pass as a local provider for Pi, Hermes, and opencode.
No credentials are written by this script.

Options:
  --dry-run                    Show what would change without writing files
  --target DIR                 Install into DIR instead of $HOME
  --no-defaults                Do not set GLM-5.2 as the default model/provider
  --no-wrap-default-binaries   Do not create ~/.local/bin/hermes or opencode wrappers
  --pass-prefix PREFIX         pass(1) prefix for Linux secrets (default: agents/cline-pass)
  -h, --help                   Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --target)
            TARGET_DIR="$2"
            shift 2
            ;;
        --no-defaults)
            SET_DEFAULTS=false
            shift
            ;;
        --no-wrap-default-binaries)
            WRAP_DEFAULT_BINARIES=false
            shift
            ;;
        --pass-prefix)
            PASS_PREFIX="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

timestamp() {
    date +%Y%m%d_%H%M%S
}

require_node() {
    if ! command -v node >/dev/null 2>&1; then
        echo "ERROR: node is required to merge Pi/opencode JSON config." >&2
        exit 1
    fi
}

backup_path() {
    local path="$1"
    local backup="${path}.bak.cline-pass-$(timestamp)"

    if [[ -L "$path" ]]; then
        readlink "$path" > "${backup}.symlink"
        echo "  backup  $path -> ${backup}.symlink"
    elif [[ -e "$path" ]]; then
        cp -p "$path" "$backup"
        echo "  backup  $path -> $backup"
    fi
}

install_file() {
    local path="$1"
    local mode="$2"
    local dir
    dir="$(dirname "$path")"

    if [[ "$DRY_RUN" == true ]]; then
        cat >/dev/null
        echo "  write  $path"
        return
    fi

    mkdir -p "$dir"
    local tmp
    tmp="$(mktemp "${dir}/.cline-pass.XXXXXX")"
    cat > "$tmp"
    chmod "$mode" "$tmp"

    if [[ -f "$path" ]] && cmp -s "$tmp" "$path"; then
        rm -f "$tmp"
        echo "  ok  $path"
        return
    fi

    if [[ -e "$path" || -L "$path" ]]; then
        backup_path "$path"
    fi

    mv "$tmp" "$path"
    echo "  write  $path"
}

install_symlink() {
    local src="$1"
    local dst="$2"
    local dir
    dir="$(dirname "$dst")"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  link  $dst -> $src"
        return
    fi

    mkdir -p "$dir"
    if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$src" ]]; then
        echo "  ok  $dst"
        return
    fi

    if [[ -e "$dst" || -L "$dst" ]]; then
        backup_path "$dst"
        rm -f "$dst"
    fi

    ln -s "$src" "$dst"
    echo "  link  $dst -> $src"
}

merge_json_configs() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "  merge  ${TARGET_DIR}/.pi/agent/models.json"
        echo "  merge  ${TARGET_DIR}/.pi/agent/settings.json"
        echo "  merge  ${TARGET_DIR}/.config/opencode/opencode.jsonc"
        return
    fi

    require_node
    TARGET_DIR="$TARGET_DIR" \
    SET_DEFAULTS="$SET_DEFAULTS" \
    CLINE_PASS_BASE_URL="$CLINE_PASS_BASE_URL" \
    GLM_MODEL="$GLM_MODEL" \
    KIMI_MODEL="$KIMI_MODEL" \
    CONTEXT_WINDOW="$CONTEXT_WINDOW" \
    MAX_TOKENS="$MAX_TOKENS" \
    node <<'NODE'
const fs = require("fs");
const path = require("path");

const target = process.env.TARGET_DIR;
const setDefaults = process.env.SET_DEFAULTS === "true";
const baseUrl = process.env.CLINE_PASS_BASE_URL;
const glmModel = process.env.GLM_MODEL;
const kimiModel = process.env.KIMI_MODEL;
const contextWindow = Number(process.env.CONTEXT_WINDOW);
const maxTokens = Number(process.env.MAX_TOKENS);

function stripJsonc(input) {
  let out = "";
  let inString = false;
  let quote = "";
  let escape = false;
  for (let i = 0; i < input.length; i++) {
    const ch = input[i];
    const next = input[i + 1];
    if (inString) {
      out += ch;
      if (escape) escape = false;
      else if (ch === "\\") escape = true;
      else if (ch === quote) inString = false;
      continue;
    }
    if (ch === '"' || ch === "'") {
      inString = true;
      quote = ch;
      out += ch;
      continue;
    }
    if (ch === "/" && next === "/") {
      while (i < input.length && input[i] !== "\n") i++;
      out += "\n";
      continue;
    }
    if (ch === "/" && next === "*") {
      i += 2;
      while (i < input.length && !(input[i] === "*" && input[i + 1] === "/")) i++;
      i++;
      continue;
    }
    out += ch;
  }
  return out.replace(/,\s*([}\]])/g, "$1");
}

function readJson(file, jsonc = false) {
  if (!fs.existsSync(file)) return {};
  const raw = fs.readFileSync(file, "utf8");
  if (!raw.trim()) return {};
  return JSON.parse(jsonc ? stripJsonc(raw) : raw);
}

function backup(file) {
  if (!fs.existsSync(file)) return;
  const stamp = new Date().toISOString().replace(/[-:T.Z]/g, "").slice(0, 14);
  const dest = `${file}.bak.cline-pass-${stamp}`;
  fs.copyFileSync(file, dest);
  console.log(`  backup  ${file} -> ${dest}`);
}

function writeJson(file, obj, space = 2) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const next = JSON.stringify(obj, null, space) + "\n";
  if (fs.existsSync(file) && fs.readFileSync(file, "utf8") === next) {
    console.log(`  ok  ${file}`);
    return;
  }
  backup(file);
  fs.writeFileSync(file, next);
  console.log(`  write  ${file}`);
}

const piModelsPath = path.join(target, ".pi/agent/models.json");
const piModels = readJson(piModelsPath);
piModels.providers = piModels.providers && typeof piModels.providers === "object" ? piModels.providers : {};
piModels.providers["cline-pass"] = {
  baseUrl,
  api: "openai-completions",
  apiKey: `!${path.join(target, ".pi/agent/bin/cline-pass-token")}`,
  headers: {
    "X-Title": "Pi Agent",
  },
  compat: {
    supportsStore: false,
    supportsDeveloperRole: false,
    supportsStrictMode: false,
  },
  models: [
    {
      id: glmModel,
      name: "GLM-5.2 (Cline Pass)",
      reasoning: true,
      input: ["text"],
      contextWindow,
      maxTokens,
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      compat: {
        supportsReasoningEffort: false,
        supportsUsageInStreaming: true,
      },
    },
    {
      id: kimiModel,
      name: "Kimi K3 (Cline Pass)",
      reasoning: true,
      input: ["text"],
      contextWindow,
      maxTokens,
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      compat: {
        supportsReasoningEffort: false,
        supportsUsageInStreaming: true,
      },
    },
  ],
};
writeJson(piModelsPath, piModels, "\t");

const piSettingsPath = path.join(target, ".pi/agent/settings.json");
const piSettings = readJson(piSettingsPath);
if (setDefaults) {
  piSettings.defaultProvider = "cline-pass";
  piSettings.defaultModel = glmModel;
}
writeJson(piSettingsPath, piSettings, 2);

const opencodePath = path.join(target, ".config/opencode/opencode.jsonc");
const opencode = readJson(opencodePath, true);
if (!opencode.$schema) opencode.$schema = "https://opencode.ai/config.json";
opencode.provider = opencode.provider && typeof opencode.provider === "object" ? opencode.provider : {};
opencode.provider["cline-pass"] = {
  npm: "@ai-sdk/openai-compatible",
  name: "Cline Pass",
  options: {
    baseURL: baseUrl,
    apiKey: "{env:OPENCODE_CLINE_API_KEY}",
  },
  models: {
    "glm-5.2": {
      id: glmModel,
      name: "GLM-5.2 (Cline Pass)",
      reasoning: true,
      tool_call: true,
      limit: {
        context: contextWindow,
        output: maxTokens,
      },
    },
    "kimi-k3": {
      id: kimiModel,
      name: "Kimi K3 (Cline Pass)",
      reasoning: true,
      tool_call: true,
      limit: {
        context: contextWindow,
        output: maxTokens,
      },
    },
  },
};
writeJson(opencodePath, opencode, 2);
NODE
}

merge_hermes_config() {
    local hermes_config="${TARGET_DIR}/.hermes/config.yaml"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  merge  $hermes_config"
        return
    fi

    mkdir -p "$(dirname "$hermes_config")"

    if command -v ruby >/dev/null 2>&1; then
        HERMES_CONFIG="$hermes_config" \
        SET_DEFAULTS="$SET_DEFAULTS" \
        CLINE_PASS_BASE_URL="$CLINE_PASS_BASE_URL" \
        GLM_MODEL="$GLM_MODEL" \
        KIMI_MODEL="$KIMI_MODEL" \
        CONTEXT_WINDOW="$CONTEXT_WINDOW" \
        ruby <<'RUBY'
require "yaml"
require "fileutils"
require "time"

path = ENV.fetch("HERMES_CONFIG")
set_defaults = ENV["SET_DEFAULTS"] == "true"
base_url = ENV.fetch("CLINE_PASS_BASE_URL")
glm_model = ENV.fetch("GLM_MODEL")
kimi_model = ENV.fetch("KIMI_MODEL")
context_window = Integer(ENV.fetch("CONTEXT_WINDOW"))

cfg = if File.exist?(path) && !File.zero?(path)
        YAML.load_file(path) || {}
      else
        {}
      end
cfg = {} unless cfg.is_a?(Hash)

if set_defaults
  cfg["model"] = {} unless cfg["model"].is_a?(Hash)
  cfg["model"]["provider"] = "cline-pass"
  cfg["model"]["default"] = glm_model
end

cfg["providers"] = {} unless cfg["providers"].is_a?(Hash)
cfg["providers"]["cline-pass"] = {
  "name" => "Cline Pass",
  "api" => base_url,
  "key_env" => "HERMES_CLINE_API_KEY",
  "api_mode" => "chat_completions",
  "default_model" => glm_model,
  "context_length" => context_window,
  "discover_models" => false,
  "models" => {
    glm_model => {
      "name" => "GLM-5.2",
      "context_length" => context_window,
    },
    kimi_model => {
      "name" => "Kimi K3",
      "context_length" => context_window,
    },
  },
}

next_content = YAML.dump(cfg)
current = File.exist?(path) ? File.read(path) : nil
if current == next_content
  puts "  ok  #{path}"
  exit
end

if File.exist?(path)
  backup = "#{path}.bak.cline-pass-#{Time.now.utc.strftime("%Y%m%d_%H%M%S")}"
  FileUtils.cp(path, backup)
  puts "  backup  #{path} -> #{backup}"
end

File.write(path, next_content)
puts "  write  #{path}"
RUBY
        return
    fi

    if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
        HERMES_CONFIG="$hermes_config" \
        SET_DEFAULTS="$SET_DEFAULTS" \
        CLINE_PASS_BASE_URL="$CLINE_PASS_BASE_URL" \
        GLM_MODEL="$GLM_MODEL" \
        KIMI_MODEL="$KIMI_MODEL" \
        CONTEXT_WINDOW="$CONTEXT_WINDOW" \
        python3 <<'PY'
import datetime
import os
import shutil
from pathlib import Path

import yaml

path = Path(os.environ["HERMES_CONFIG"])
set_defaults = os.environ["SET_DEFAULTS"] == "true"
base_url = os.environ["CLINE_PASS_BASE_URL"]
glm_model = os.environ["GLM_MODEL"]
kimi_model = os.environ["KIMI_MODEL"]
context_window = int(os.environ["CONTEXT_WINDOW"])

if path.exists() and path.stat().st_size:
    with path.open("r", encoding="utf-8") as fh:
        cfg = yaml.safe_load(fh) or {}
else:
    cfg = {}
if not isinstance(cfg, dict):
    cfg = {}

if set_defaults:
    cfg.setdefault("model", {})
    if not isinstance(cfg["model"], dict):
        cfg["model"] = {}
    cfg["model"]["provider"] = "cline-pass"
    cfg["model"]["default"] = glm_model

cfg.setdefault("providers", {})
if not isinstance(cfg["providers"], dict):
    cfg["providers"] = {}
cfg["providers"]["cline-pass"] = {
    "name": "Cline Pass",
    "api": base_url,
    "key_env": "HERMES_CLINE_API_KEY",
    "api_mode": "chat_completions",
    "default_model": glm_model,
    "context_length": context_window,
    "discover_models": False,
    "models": {
        glm_model: {
            "name": "GLM-5.2",
            "context_length": context_window,
        },
        kimi_model: {
            "name": "Kimi K3",
            "context_length": context_window,
        },
    },
}

next_content = yaml.safe_dump(cfg, sort_keys=False)
current = path.read_text(encoding="utf-8") if path.exists() else None
if current == next_content:
    print(f"  ok  {path}")
    raise SystemExit

if path.exists():
    stamp = datetime.datetime.now(datetime.UTC).strftime("%Y%m%d_%H%M%S")
    backup = path.with_name(f"{path.name}.bak.cline-pass-{stamp}")
    shutil.copy2(path, backup)
    print(f"  backup  {path} -> {backup}")

path.write_text(next_content, encoding="utf-8")
print(f"  write  {path}")
PY
        return
    fi

    echo "  WARN  ruby or python3+PyYAML is required to merge Hermes YAML; skipping" >&2
}

preserve_default_binary() {
    local name="$1"
    local local_bin="${TARGET_DIR}/.local/bin"
    local path="${local_bin}/${name}"
    local saved="${local_bin}/${name}-bin"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  preserve  $path -> $saved"
        return
    fi

    if [[ -e "$saved" || -L "$saved" ]]; then
        return
    fi
    if [[ ! -e "$path" && ! -L "$path" ]]; then
        return
    fi
    if [[ -f "$path" ]] && grep -q "generated by setup-cline-pass-agents.sh" "$path"; then
        return
    fi

    mv "$path" "$saved"
    echo "  preserve  $path -> $saved"
}

install_key_helpers() {
    local local_bin="${TARGET_DIR}/.local/bin"

    install_file "${local_bin}/cline-pass-key" 700 <<'EOF'
#!/bin/sh
# generated by setup-cline-pass-agents.sh
set -eu

service="${1:-${CLINE_PASS_KEYCHAIN_SERVICE:-cline-pass-api-key}}"
account="${2:-${CLINE_PASS_KEYCHAIN_ACCOUNT:-}}"
pass_entry="${3:-${CLINE_PASS_PASS_ENTRY:-}}"

if [ -n "${CLINE_API_KEY:-}" ]; then
  printf "%s" "$CLINE_API_KEY"
  exit 0
fi

if [ -n "$pass_entry" ] && command -v pass >/dev/null 2>&1; then
  pass show "$pass_entry" && exit 0
fi

if command -v security >/dev/null 2>&1; then
  if [ -n "$account" ]; then
    security find-generic-password -s "$service" -a "$account" -w 2>/dev/null && exit 0
  fi
  security find-generic-password -s "$service" -w 2>/dev/null && exit 0
  security find-generic-password -a "$service" -w 2>/dev/null && exit 0
  security find-generic-password -s "$service" -a "$service" -w 2>/dev/null && exit 0
fi

providers_path="${CLINE_PROVIDERS_JSON:-$HOME/.cline/data/settings/providers.json}"
provider="${CLINE_PASS_PROVIDER:-cline-pass}"
min_validity_ms="${CLINE_PASS_MIN_VALIDITY_MS:-30000}"

if command -v node >/dev/null 2>&1 && [ -f "$providers_path" ]; then
  node - "$providers_path" "$provider" "$min_validity_ms" <<'NODE'
const fs = require("fs");
const providersPath = process.argv[2];
const provider = process.argv[3];
const minValidityMs = Number(process.argv[4] || 30000);

try {
  const data = JSON.parse(fs.readFileSync(providersPath, "utf8"));
  const auth = data.providers?.[provider]?.settings?.auth;
  const token = String(auth?.accessToken || "").trim();
  const expiresAt = Number(auth?.expiresAt || 0);
  if (!token) process.exit(1);
  if (expiresAt && expiresAt - Date.now() < minValidityMs) process.exit(1);
  process.stdout.write(token);
} catch {
  process.exit(1);
}
NODE
  exit $?
fi

exit 1
EOF

    install_file "${TARGET_DIR}/.pi/agent/bin/cline-pass-token" 700 <<EOF
#!/bin/sh
# generated by setup-cline-pass-agents.sh
set -eu

if [ -n "\${PI_CLINE_API_KEY:-}" ]; then
  printf "%s" "\$PI_CLINE_API_KEY"
  exit 0
fi

entry="\${PI_CLINE_PASS_ENTRY:-\${CLINE_PASS_PASS_PREFIX:-${PASS_PREFIX}}/pi}"
exec "${local_bin}/cline-pass-key" "\${PI_CLINE_KEYCHAIN_SERVICE:-pi-cline-api-key}" "\${PI_CLINE_KEYCHAIN_ACCOUNT:-}" "\$entry"
EOF

    install_file "${TARGET_DIR}/.hermes/bin/cline-api-key" 700 <<EOF
#!/bin/sh
# generated by setup-cline-pass-agents.sh
set -eu

if [ -n "\${HERMES_CLINE_API_KEY:-}" ]; then
  printf "%s" "\$HERMES_CLINE_API_KEY"
  exit 0
fi

entry="\${HERMES_CLINE_PASS_ENTRY:-\${CLINE_PASS_PASS_PREFIX:-${PASS_PREFIX}}/hermes}"
exec "${local_bin}/cline-pass-key" "\${HERMES_CLINE_KEYCHAIN_SERVICE:-hermes-cline-api-key}" "\${HERMES_CLINE_KEYCHAIN_ACCOUNT:-}" "\$entry"
EOF

    install_file "${TARGET_DIR}/.config/opencode/bin/cline-api-key" 700 <<EOF
#!/bin/sh
# generated by setup-cline-pass-agents.sh
set -eu

if [ -n "\${OPENCODE_CLINE_API_KEY:-}" ]; then
  printf "%s" "\$OPENCODE_CLINE_API_KEY"
  exit 0
fi

entry="\${OPENCODE_CLINE_PASS_ENTRY:-\${CLINE_PASS_PASS_PREFIX:-${PASS_PREFIX}}/opencode}"
exec "${local_bin}/cline-pass-key" "\${OPENCODE_CLINE_KEYCHAIN_SERVICE:-opencode-cline-api-key}" "\${OPENCODE_CLINE_KEYCHAIN_ACCOUNT:-}" "\$entry"
EOF
}

install_launchers() {
    local local_bin="${TARGET_DIR}/.local/bin"

    install_file "${TARGET_DIR}/.hermes/bin/hermes-cline" 755 <<EOF
#!/bin/sh
# generated by setup-cline-pass-agents.sh
set -eu

key="\$("${TARGET_DIR}/.hermes/bin/cline-api-key")"
export HERMES_CLINE_API_KEY="\$key"

has_provider=0
has_model=0
for arg in "\$@"; do
  case "\$arg" in
    --provider|--provider=*) has_provider=1 ;;
    -m|--model|--model=*) has_model=1 ;;
  esac
done

if [ "\$has_provider" -eq 0 ]; then
  set -- --provider custom:cline-pass "\$@"
fi
if [ "\$has_model" -eq 0 ]; then
  set -- --model ${GLM_MODEL} "\$@"
fi

for candidate in "\${HERMES_BIN:-}" "${local_bin}/hermes-bin" "${TARGET_DIR}/.hermes/venvs/hermes-dev/bin/hermes" "${local_bin}/hermes" /opt/homebrew/bin/hermes /usr/local/bin/hermes /usr/bin/hermes; do
  [ -n "\$candidate" ] || continue
  [ -x "\$candidate" ] || continue
  exec "\$candidate" "\$@"
done

printf "hermes executable not found. Install Hermes or set HERMES_BIN.\\n" >&2
exit 127
EOF
    install_symlink "${TARGET_DIR}/.hermes/bin/hermes-cline" "${local_bin}/hermes-cline"

    install_file "${TARGET_DIR}/.config/opencode/bin/opencode-cline" 755 <<EOF
#!/bin/sh
# generated by setup-cline-pass-agents.sh
set -eu

key="\$("${TARGET_DIR}/.config/opencode/bin/cline-api-key")"
export OPENCODE_CLINE_API_KEY="\$key"

has_model=0
for arg in "\$@"; do
  case "\$arg" in
    -m|--model|--model=*) has_model=1 ;;
  esac
done

if [ "\$has_model" -eq 0 ]; then
  set -- --model ${GLM_MODEL} "\$@"
fi

for candidate in "\${OPENCODE_BIN:-}" "${local_bin}/opencode-bin" "${local_bin}/opencode" /opt/homebrew/bin/opencode /usr/local/bin/opencode /usr/bin/opencode; do
  [ -n "\$candidate" ] || continue
  [ -x "\$candidate" ] || continue
  exec "\$candidate" "\$@"
done

printf "opencode executable not found. Install opencode or set OPENCODE_BIN.\\n" >&2
exit 127
EOF
    install_symlink "${TARGET_DIR}/.config/opencode/bin/opencode-cline" "${local_bin}/opencode-cline"

    if [[ "$WRAP_DEFAULT_BINARIES" != true ]]; then
        return
    fi

    preserve_default_binary "hermes"
    preserve_default_binary "opencode"

    install_file "${local_bin}/hermes" 755 <<EOF
#!/bin/sh
# generated by setup-cline-pass-agents.sh
set -eu

if [ -z "\${HERMES_CLINE_API_KEY:-}" ]; then
  if key="\$("${TARGET_DIR}/.hermes/bin/cline-api-key" 2>/dev/null)"; then
    export HERMES_CLINE_API_KEY="\$key"
  fi
fi

for candidate in "\${HERMES_BIN:-}" "${local_bin}/hermes-bin" "${TARGET_DIR}/.hermes/venvs/hermes-dev/bin/hermes" /opt/homebrew/bin/hermes /usr/local/bin/hermes /usr/bin/hermes; do
  [ -n "\$candidate" ] || continue
  [ -x "\$candidate" ] || continue
  exec "\$candidate" "\$@"
done

printf "hermes executable not found. Install Hermes or set HERMES_BIN.\\n" >&2
exit 127
EOF

    install_file "${local_bin}/opencode" 755 <<EOF
#!/bin/sh
# generated by setup-cline-pass-agents.sh
set -eu

if [ -z "\${OPENCODE_CLINE_API_KEY:-}" ]; then
  if key="\$("${TARGET_DIR}/.config/opencode/bin/cline-api-key" 2>/dev/null)"; then
    export OPENCODE_CLINE_API_KEY="\$key"
  fi
fi

for candidate in "\${OPENCODE_BIN:-}" "${local_bin}/opencode-bin" /opt/homebrew/bin/opencode /usr/local/bin/opencode /usr/bin/opencode; do
  [ -n "\$candidate" ] || continue
  [ -x "\$candidate" ] || continue
  exec "\$candidate" "\$@"
done

printf "opencode executable not found. Install opencode or set OPENCODE_BIN.\\n" >&2
exit 127
EOF
}

print_next_steps() {
    cat <<EOF

Credential setup is intentionally separate.

macOS Keychain example:
  security add-generic-password -a "\$USER" -s pi-cline-api-key -w '<cline-pass-api-key>' -U
  security add-generic-password -a "\$USER" -s hermes-cline-api-key -w '<cline-pass-api-key>' -U
  security add-generic-password -a "\$USER" -s opencode-cline-api-key -w '<cline-pass-api-key>' -U

Portable env-var fallback:
  export CLINE_API_KEY='<cline-pass-api-key>'

Linux pass example:
  pass insert ${PASS_PREFIX}/pi
  pass insert ${PASS_PREFIX}/hermes
  pass insert ${PASS_PREFIX}/opencode

Configured models:
  ${GLM_MODEL}
  ${KIMI_MODEL}

Launchers:
  pi
  hermes
  hermes-cline
  opencode
  opencode-cline
EOF
}

if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$TARGET_DIR"
    TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
fi

echo "Cline Pass agent setup -> ${TARGET_DIR}"
if [[ "$DRY_RUN" == true ]]; then
    echo "(dry run - no changes will be made)"
fi

echo ""
echo "Config:"
merge_json_configs
merge_hermes_config

echo ""
echo "Key helpers:"
install_key_helpers

echo ""
echo "Launchers:"
install_launchers

echo ""
echo "Done."
print_next_steps
