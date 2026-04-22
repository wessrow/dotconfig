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

## Daily Update on Existing Machines

```bash
cd ~/.config
git pull
./install.sh
```
