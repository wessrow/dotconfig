# Dotfiles Bootstrap

This repo is intended to be cloned to `~/.config` and used as the single source of truth for shell/editor/tooling setup.

## Fresh Machine Setup

## 1) Clone this repo

```bash
git clone <your-repo-url> ~/.config
cd ~/.config
```

## 2) Point Zsh to this repo

Create or edit `~/.zshenv`:

```zsh
export PATH="$HOME/.local/bin:$PATH"
export ZDOTDIR="$HOME/.config/zsh"
```

Then start a new shell:

```bash
exec zsh
```

## 3) Install required CLI tools

```bash
brew install fzf
brew install fd
brew install bat
brew install eza
brew install tmux
```

## 4) Optional tools used by aliases/config

```bash
brew install neovim
brew install libpq
brew install bun
```

## Reproducibility Notes

- `oh-my-zsh` is tracked directly in this repo at `~/.config/oh-my-zsh`.
- `nvim` (including `init.lua`) is tracked directly in this repo at `~/.config/nvim`.
- Custom Oh My Zsh plugins/themes are tracked in this repo at `~/.config/zsh/oh-my-zsh-custom`.
- `~/.config/zsh/.zshrc` sets `ZSH_CUSTOM` to that tracked directory, so your custom plugin/theme set is reproducible across machines.
- tmux plugins under `~/.config/tmux/plugins` are tracked directly in this repo.

## Daily Update on Existing Machines

```bash
cd ~/.config
git pull
```
