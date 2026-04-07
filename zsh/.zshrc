# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Editor
export EDITOR='nvim'

# PATH
export PATH="$HOME/.local/bin:$PATH"

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
