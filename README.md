# Dotfiles Bootstrap

This repo is intended to be cloned anywhere you want and used as the single source of truth for shell/editor/tooling setup.

Only config files are tracked here. Third-party source trees such as `oh-my-zsh`, zsh plugins/themes, and tmux plugins are installed locally by `install.sh` and ignored by git.

## Fresh Machine Setup

## 1) Clone this repo

```bash
git clone https://github.com/wessrow/dotconfig.git ~/.config
cd ~/.config
```

## 2) Point Zsh to this repo

Create or edit `~/.zshenv`:

```zsh
export PATH="$HOME/.local/bin:$PATH"
export ZDOTDIR="$HOME/.config/zsh"
```

## 3) Run the installer

```bash
chmod +x ./install.sh
./install.sh
```

`install.sh` installs these Homebrew packages (when Homebrew is available):

```bash
brew install bat eza fd fzf libpq neovim tmux
brew install oven-sh/bun/bun
```

You can install them manually first if you prefer; the script will skip already-installed packages.

## 4) Start a new shell

```bash
exec zsh
```

## Reproducibility Notes

- Tracked: shell config, tmux config, Neovim config, and bootstrap scripts.
- Installed locally by `install.sh`: `oh-my-zsh`, `powerlevel10k`, zsh plugins, and tmux plugins.
- Neovim plugins are managed by `lazy.nvim` from inside `nvim/init.lua`; they are not vendored in this repo.

## Claude Usage tmux Widget

The tmux status line shows the Claude Code 5-hour ("session") usage percentage
via `tmux/claude_usage.sh`. Claude Code only refreshes those numbers on
interactive startup and when you run `/usage`, so a poller keeps them current:

- `tmux/claude_usage_poll.sh` runs `claude -p '/usage'` (costs $0 / 0 tokens)
  and caches the result to `~/.cache/claude-usage/usage.json`.
- `tmux/claude_usage.sh` reads that cache (falling back to `~/.claude.json`),
  and appends `?` if the cache is older than 30 minutes.

**macOS:** `install.sh` renders `launchd/local.claude-usage.plist.template` to
`~/Library/LaunchAgents/local.claude-usage.plist` and loads it (polls every
180s). Manage it with:

```bash
launchctl kickstart -k gui/$(id -u)/local.claude-usage   # run now
launchctl bootout   gui/$(id -u)/local.claude-usage       # stop/remove
tail -f ~/.cache/claude-usage/poll.log                    # debug
```

**Linux / no launchd:** add a cron entry instead:

```cron
*/3 * * * * $HOME/.config/tmux/claude_usage_poll.sh >> $HOME/.cache/claude-usage/poll.log 2>&1
```

## Daily Update on Existing Machines

```bash
cd ~/.config
git pull
./install.sh
```
