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

install_claude_usage_agent() {
  # Keeps the tmux Claude usage widget fresh. Claude Code only refreshes its
  # usage numbers on interactive startup / `/usage`, so a launchd agent polls
  # for them on a timer. macOS only; on Linux add a cron entry instead (see
  # README).
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Not macOS. Skipping Claude usage launchd agent (see README for cron)."
    return
  fi

  local label="local.claude-usage"
  local template="${CONFIG_HOME}/launchd/${label}.plist.template"
  local dest="${HOME}/Library/LaunchAgents/${label}.plist"
  local poll_script="${CONFIG_HOME}/tmux/claude_usage_poll.sh"
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage"
  local log_file="${cache_dir}/poll.log"

  if [[ ! -f "$template" ]]; then
    echo "Missing $template. Skipping Claude usage agent."
    return
  fi

  chmod +x "$poll_script" "${CONFIG_HOME}/tmux/claude_usage.sh"
  mkdir -p "${HOME}/Library/LaunchAgents" "$cache_dir"

  command -v claude >/dev/null 2>&1 || \
    echo "Note: 'claude' not on PATH yet - the agent will start working once it is."

  sed -e "s|__POLL_SCRIPT__|${poll_script}|g" \
      -e "s|__PATH__|${HOME}/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin|g" \
      -e "s|__HOME__|${HOME}|g" \
      -e "s|__LOG__|${log_file}|g" \
      "$template" > "$dest"

  local domain="gui/$(id -u)"
  launchctl bootout "${domain}/${label}" 2>/dev/null || true
  if launchctl bootstrap "$domain" "$dest" 2>/dev/null; then
    launchctl kickstart -k "${domain}/${label}" 2>/dev/null || true
  else
    # Older launchctl
    launchctl unload "$dest" 2>/dev/null || true
    launchctl load -w "$dest" 2>/dev/null || true
  fi
  echo "Installed launchd agent ${label} (polls every 180s, log: ${log_file})."
}

mkdir -p "$ZSH_CUSTOM_DIR/plugins" "$ZSH_CUSTOM_DIR/themes" "$TMUX_PLUGIN_DIR"

echo "Using config root: $CONFIG_HOME"

install_brew_packages

clone_or_update https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
clone_or_update https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM_DIR/plugins/fast-syntax-highlighting"
clone_or_update https://github.com/Aloxaf/fzf-tab.git "$ZSH_CUSTOM_DIR/plugins/fzf-tab"
clone_or_update https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM_DIR/themes/powerlevel10k"

clone_or_update https://github.com/tmux-plugins/tpm "$TMUX_PLUGIN_DIR/tpm"
clone_or_update https://github.com/tmux-plugins/tmux-sensible "$TMUX_PLUGIN_DIR/tmux-sensible"
clone_or_update https://github.com/dracula/tmux "$TMUX_PLUGIN_DIR/tmux"

install_claude_usage_agent

echo "Bootstrap complete."
echo "If this repo is not cloned to ~/.config, set this in ~/.zshenv:"
echo "export ZDOTDIR=\"$ZSH_DIR\""
echo "Next steps: exec zsh"