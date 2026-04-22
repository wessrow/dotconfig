#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="$SCRIPT_DIR"
ZSH_DIR="${CONFIG_HOME}/zsh"
OH_MY_ZSH_DIR="${CONFIG_HOME}/oh-my-zsh"
ZSH_CUSTOM_DIR="${ZSH_DIR}/oh-my-zsh-custom"
TMUX_PLUGIN_DIR="${CONFIG_HOME}/tmux/plugins"

clone_or_update() {
  local repo="$1"
  local target="$2"

  if [[ -d "$target/.git" ]]; then
    git -C "$target" fetch --depth=1 origin
    git -C "$target" reset --hard origin/HEAD
    return
  fi

  rm -rf "$target"
  git clone --depth=1 "$repo" "$target"
}

install_brew_packages() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Skipping brew installs."
    return
  fi

  local packages=(
    bat
    eza
    fd
    fzf
    libpq
    neovim
    tmux
  )

  local package
  for package in "${packages[@]}"; do
    brew list "$package" >/dev/null 2>&1 || brew install "$package"
  done

  if ! command -v bun >/dev/null 2>&1; then
    brew list oven-sh/bun/bun >/dev/null 2>&1 || brew install oven-sh/bun/bun
  fi
}

mkdir -p "$ZSH_CUSTOM_DIR/plugins" "$ZSH_CUSTOM_DIR/themes" "$TMUX_PLUGIN_DIR"

echo "Using config root: $CONFIG_HOME"

install_brew_packages

clone_or_update https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
clone_or_update https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/fast-syntax-highlighting"
clone_or_update https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM_DIR/plugins/zsh-autocomplete"
clone_or_update https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM_DIR/themes/powerlevel10k"

clone_or_update https://github.com/tmux-plugins/tpm "$TMUX_PLUGIN_DIR/tpm"
clone_or_update https://github.com/tmux-plugins/tmux-sensible "$TMUX_PLUGIN_DIR/tmux-sensible"
clone_or_update https://github.com/dracula/tmux "$TMUX_PLUGIN_DIR/tmux"

echo "Bootstrap complete."
echo "If this repo is not cloned to ~/.config, set this in ~/.zshenv:"
echo "export ZDOTDIR=\"$ZSH_DIR\""
echo "Next steps: exec zsh"