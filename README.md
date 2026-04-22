# Dotfiles Bootstrap

This repo is intended to be cloned to `~/.config` and used as the single source of truth for shell/editor/tooling setup.

## Fresh Machine Setup

## 1) Clone this repo

```bash
git clone <your-repo-url> ~/.config
cd ~/.config
```

## 2) Initialize submodules

```bash
git submodule sync --recursive
git submodule update --init --recursive
```

This pulls nested repos such as `oh-my-zsh`, `nvim`, and tmux plugins.

## 3) Point Zsh to this repo

Create or edit `~/.zshenv`:

```zsh
export PATH="$HOME/.local/bin:$PATH"
export ZDOTDIR="$HOME/.config/zsh"
```

Then start a new shell:

```bash
exec zsh
```

## 4) Install required CLI tools

```bash
brew install fzf
brew install fd
brew install bat
brew install eza
brew install tmux
```

## 5) Optional tools used by aliases/config

```bash
brew install neovim
brew install libpq
brew install bun
```

## Reproducibility Notes

- `oh-my-zsh` itself is tracked as a submodule at `~/.config/oh-my-zsh`.
- Custom Oh My Zsh plugins/themes are tracked in this repo at `~/.config/zsh/oh-my-zsh-custom`.
- `~/.config/zsh/.zshrc` sets `ZSH_CUSTOM` to that tracked directory, so your custom plugin/theme set is reproducible across machines.

## Daily Update on Existing Machines

```bash
cd ~/.config
git pull
git submodule sync --recursive
git submodule update --init --recursive
```
