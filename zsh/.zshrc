# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-${ZDOTDIR:-$HOME}/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-${ZDOTDIR:-$HOME}/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.config/oh-my-zsh"
export ZSH_CUSTOM="$HOME/.config/zsh/oh-my-zsh-custom"
export XDG_CONFIG_HOME="$HOME/.config/"

# Set up PATH early so tmux and other tools are found before plugins load
export GOPATH="/Users/$USER/go"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/opt/libpq/bin:/Users/$USER/go/bin:/Users/$USER/.bun/bin:/Users/$USER/Documents/dev/misc:/Library/Frameworks/Python.framework/Versions/3.12/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"


# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# Raise the file-descriptor limit (harmless; a few tools open many files)
ulimit -n 4096 2>/dev/null || true

# NOTE: fast-syntax-highlighting must be the LAST ZLE plugin in this list -
# it wraps every widget, so anything loaded after it silently breaks.
# zsh-autocomplete was removed: it rebinds the arrow keys to async menu
# widgets whose worker processes die in tmux panes (completion stops until
# `exec zsh`) and whose redraws corrupt Up-arrow history recall under p10k.
plugins=(docker git tmux python gitignore dotenv zsh-autosuggestions fast-syntax-highlighting)

ZSH_TMUX_AUTOSTART=true
ZSH_TMUX_AUTONAME_SESSION=true
PYTHON_VENV_NAMES=($PYTHON_VENV_NAME venv)
PYTHON_AUTO_VRUN=true

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  echo "oh-my-zsh is not installed yet. Run ~/.config/install.sh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
if [[ -f ~/.config/zsh/.p10k.zsh ]] && [[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  source ~/.config/zsh/.p10k.zsh
fi

# Loading `.env` on VS Code embeded terminal
if [[ "$TERM_PROGRAM" == "vscode" && -f ".env" ]]; then
  export $(cat .env | xargs)
  echo "✅ loaded .env"
fi

# ---- FZF -----

# Set up fzf key bindings and fuzzy completion (safe eval)
if command -v fzf &> /dev/null; then
  eval "$(fzf --zsh 2>/dev/null)" || true
fi

# -- Use fd instead of fzf --

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# ---- Eza (better ls) -----

alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time"
alias tui="/Users/gustav/Documents/dev/acebit/naas-tui/run_tui.sh"

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}

alias vim="nvim"
alias cat="bat"
alias dev="cd ~/Documents/dev/"

# ---- History ----
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_FCNTL_LOCK        # atomic locking - safe concurrent writes from many tmux panes
setopt HIST_IGNORE_ALL_DUPS  # keep only the most recent copy of any duplicated command
setopt HIST_REDUCE_BLANKS

# ---- Down = prefix-search on what's already typed ----
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search  # Down
bindkey '^[OB' down-line-or-beginning-search  # Down (application cursor mode)

# ---- Up = fzf history picker: numbered, fuzzy, scrollable (same as Ctrl-R) ----
# fzf-history-widget is defined by `eval "$(fzf --zsh)"` above. Fall back to
# prefix search if fzf isn't available.
if (( $+widgets[fzf-history-widget] )); then
  bindkey '^[[A' fzf-history-widget           # Up
  bindkey '^[OA' fzf-history-widget           # Up (application cursor mode)
else
  bindkey '^[[A' up-line-or-beginning-search
  bindkey '^[OA' up-line-or-beginning-search
fi

# Classic Ctrl-R look: bottom strip, prompt at the bottom, matches listed above it
export FZF_CTRL_R_OPTS="--height=40%"

export KUBECONFIG=~/.kube/config:~/.kube/config_lab

# bun completions
[ -s "/Users/$USER/.bun/_bun" ] && source "/Users/$USER/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export KUBECONFIG=/Users/gustav/vgr-klusters:/Users/gustav/.kube/acebit-kluster

# opencode
export PATH=/Users/gustav/.opencode/bin:$PATH
