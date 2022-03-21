# `ls` aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Dotfile configuration
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# Finding WAN IP
alias wanip='dig @resolver4.opendns.com myip.opendns.com +short'

# Terminal copy/paste
if [[ "$OSTYPE" != "darwin"* ]]; then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi

# Weather
alias weather='curl wttr.in/Beloit'

# Drupal
alias drupalcs="phpcs --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,css,info,txt,md,yml'"
alias drupalcsp="phpcs --standard=DrupalPractice --extensions='php,module,inc,install,test,profile,theme,css,info,txt,md,yml'"
alias drupalcbf="phpcbf --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,css,info,txt,md,yml'"
