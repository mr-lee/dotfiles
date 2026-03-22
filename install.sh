#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${HOME}"
DRY_RUN=false

usage() {
    echo "Usage: install.sh [--dry-run] [--target DIR]"
    echo ""
    echo "Symlinks dotfiles from this repo into your home directory,"
    echo "installs Starship prompt, zsh plugins, and wires up .zshrc.personal."
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would be done without making changes"
    echo "  --target     Target directory (default: \$HOME)"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --target) TARGET_DIR="$2"; shift 2 ;;
        --help|-h) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# Files to symlink (source relative to DOTFILES_DIR -> target relative to TARGET_DIR)
FILES=(
    .gitconfig
    .gitignore_global
    .tmux.conf
    .vimrc
    .zshrc.personal
)

# Starship config goes in ~/.config/
STARSHIP_SRC="${DOTFILES_DIR}/starship.toml"
STARSHIP_DST="${TARGET_DIR}/.config/starship.toml"

# Zsh plugins to clone
ZSH_PLUGINS_DIR="${TARGET_DIR}/.zsh/plugins"
ZSH_PLUGINS=(
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-syntax-highlighting"
)

link_file() {
    local src="$1"
    local dst="$2"

    if [[ -L "$dst" ]]; then
        local current
        current="$(readlink "$dst")"
        if [[ "$current" == "$src" ]]; then
            echo "  ok  $dst (already linked)"
            return
        fi
        echo "  update  $dst (relink: $current -> $src)"
    elif [[ -e "$dst" ]]; then
        echo "  backup  $dst -> ${dst}.bak"
        if [[ "$DRY_RUN" == false ]]; then
            mv "$dst" "${dst}.bak"
        fi
    else
        echo "  link  $dst -> $src"
    fi

    if [[ "$DRY_RUN" == false ]]; then
        ln -sf "$src" "$dst"
    fi
}

echo "Dotfiles install: ${DOTFILES_DIR} -> ${TARGET_DIR}"
if [[ "$DRY_RUN" == true ]]; then
    echo "(dry run - no changes will be made)"
fi

# --- Symlink dotfiles ---
echo ""
echo "Symlinks:"
for file in "${FILES[@]}"; do
    link_file "${DOTFILES_DIR}/${file}" "${TARGET_DIR}/${file}"
done

# --- Starship config ---
echo ""
echo "Starship:"
if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "${TARGET_DIR}/.config"
fi
link_file "${STARSHIP_SRC}" "${STARSHIP_DST}"

# --- Install Starship if missing ---
if ! command -v starship &>/dev/null; then
    echo "  install  starship (via brew)"
    if [[ "$DRY_RUN" == false ]]; then
        if command -v brew &>/dev/null; then
            brew install starship
        else
            echo "  WARN  brew not found - install starship manually: https://starship.rs"
        fi
    fi
else
    echo "  ok  starship (already installed)"
fi

# --- Zsh plugins ---
echo ""
echo "Zsh plugins:"
for plugin in "${ZSH_PLUGINS[@]}"; do
    plugin_name="${plugin##*/}"
    plugin_dir="${ZSH_PLUGINS_DIR}/${plugin_name}"
    if [[ -d "$plugin_dir" ]]; then
        echo "  ok  ${plugin_name} (already cloned)"
    else
        echo "  clone  ${plugin} -> ${plugin_dir}"
        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "${ZSH_PLUGINS_DIR}"
            git clone --depth 1 "https://github.com/${plugin}.git" "$plugin_dir"
        fi
    fi
done

# --- Wire up .zshrc.personal ---
echo ""
echo "Zsh integration:"
ZSHRC="${TARGET_DIR}/.zshrc"
SOURCE_LINE='[[ -f ~/.zshrc.personal ]] && source ~/.zshrc.personal'
if [[ -f "$ZSHRC" ]]; then
    if grep -qF ".zshrc.personal" "$ZSHRC"; then
        echo "  ok  .zshrc already sources .zshrc.personal"
    else
        echo "  append  adding 'source ~/.zshrc.personal' to .zshrc"
        if [[ "$DRY_RUN" == false ]]; then
            echo "" >> "$ZSHRC"
            echo "# Personal zsh config (github.com/mr-lee/dotfiles)" >> "$ZSHRC"
            echo "$SOURCE_LINE" >> "$ZSHRC"
        fi
    fi
else
    echo "  skip  no .zshrc found - create one and add: ${SOURCE_LINE}"
fi

# --- Post-install reminders ---
echo ""
echo "Done!"
echo ""
echo "Post-install:"
echo "  - Run 'vim +PlugInstall +qa' to bootstrap vim plugins"
echo "  - Open a new shell to activate Starship and zsh plugins"
