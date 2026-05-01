# Completion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
setopt COMPLETE_ALIASES

# History
HISTFILE="$XDG_CONFIG_HOME/zsh/history"
HISTSIZE=10000000
SAVEHIST=10000000
setopt INC_APPEND_HISTORY

# Vi mode
bindkey -v
export KEYTIMEOUT=1

# Change cursor shape for vi modes
function zle-keymap-select {
  if [[ $KEYMAP == vicmd ]] || [[ $1 == 'block' ]]; then
    echo -ne '\e[2 q'
  elif [[ $KEYMAP == main ]] || [[ $KEYMAP == viins ]] || [[ $1 == 'beam' ]]; then
    echo -ne '\e[6 q'
  fi
}
zle -N zle-keymap-select
echo -ne '\e[6 q' # beam cursor on startup

# Edit command in nvim with ctrl-e
autoload edit-command-line
zle -N edit-command-line
bindkey '^e' edit-command-line

# Editor
export EDITOR='nvim'

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.composer/vendor/bin:$PATH"

# Herd
export HERD_PHP_82_INI_SCAN_DIR="/Users/joseph/Library/Application Support/Herd/config/php/82/"
export HERD_PHP_83_INI_SCAN_DIR="/Users/joseph/Library/Application Support/Herd/config/php/83/"
export HERD_PHP_84_INI_SCAN_DIR="/Users/joseph/Library/Application Support/Herd/config/php/84/"
export HERD_PHP_85_INI_SCAN_DIR="/Users/joseph/Library/Application Support/Herd/config/php/85/"
export PATH="/Users/joseph/Library/Application Support/Herd/bin/":$PATH
export NVM_DIR="/Users/joseph/Library/Application Support/Herd/config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ]] && builtin source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"

# Herd aliases
alias ci="herd composer install"
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
alias ar="herd php artisan"
alias art="herd coverage ./vendor/bin/pest --parallel --coverage"

# Directory aliases
alias ae="cd ~/code/ae"

# Bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Secrets
[ -f "$HOME/.secrets" ] && source "$HOME/.secrets"

# Prompt
eval "$(starship init zsh)"

# Syntax highlighting (must be last)
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
