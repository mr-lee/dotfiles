#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${HOME}"
DRY_RUN=false

usage() {
    echo "Usage: install.sh [--dry-run] [--target DIR]"
    echo ""
    echo "Symlinks dotfiles from this repo into your home directory."
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
)

# Files to skip - these need manual setup or are managed by other tools
SKIP=(
    .zshrc           # Often Ansible-managed; handle manually
    .mrlee.zsh-theme # Depends on zsh setup decision
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
echo ""

for file in "${FILES[@]}"; do
    link_file "${DOTFILES_DIR}/${file}" "${TARGET_DIR}/${file}"
done

echo ""
echo "Skipped (manual setup):"
for file in "${SKIP[@]}"; do
    echo "  skip  ${file}"
done

echo ""
echo "Done. Run 'vim +PlugInstall +qa' to bootstrap vim plugins."
