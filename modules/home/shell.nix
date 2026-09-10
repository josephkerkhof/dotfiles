{...}: {
  home = {
    sessionPath = [
      "$HOME/.local/bin"
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;

      history = {
        ignoreDups = false;
        ignoreSpace = false;
        path = "$HOME/.config/zsh/history";
        size = 10000000;
        save = 10000000;
        share = false;
      };

      shellAliases = {
        ae = "cd ~/code/ae";
        ar = "herd php artisan";
        art = "herd coverage ./vendor/bin/pest --parallel --processes=6 --tia";
        ci = "herd composer install";
        qa = "herd composer qa";
        sail = ''sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'';
      };

      initContent = ''
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
        setopt COMPLETE_ALIASES INC_APPEND_HISTORY

        bindkey -v
        export KEYTIMEOUT=10

        function zle-keymap-select {
          if [[ $KEYMAP == vicmd ]] || [[ $1 == block ]]; then
            echo -ne '\e[2 q'
          elif [[ $KEYMAP == main ]] || [[ $KEYMAP == viins ]] || [[ $1 == beam ]]; then
            echo -ne '\e[6 q'
          fi
        }
        zle -N zle-keymap-select
        echo -ne '\e[6 q'

        autoload edit-command-line
        zle -N edit-command-line
        bindkey '^e' edit-command-line

        if [[ -d "$HOME/Library/Application Support/Herd" ]]; then
          export HERD_PHP_82_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/82/"
          export HERD_PHP_83_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/83/"
          export HERD_PHP_84_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/84/"
          export HERD_PHP_85_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/85/"
          path=("$HOME/Library/Application Support/Herd/bin" $path)

          export NVM_DIR="$HOME/Library/Application Support/Herd/config/nvm"
          [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
          [[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ]] && \
            source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"

          xdebug() {
            local dir="$HOME/Library/Application Support/Herd/config/php" want="$1" mode
            if [[ -z "$want" ]]; then
              grep -q '^xdebug.mode=debug' "$dir/85/php.ini" && want=off || want=on
            fi
            case "$want" in
              on) mode=debug ;;
              off) mode=off ;;
              *) print -u2 "usage: xdebug [on|off]"; return 1 ;;
            esac
            for ini in "$dir"/8{4,5}/php.ini; do
              sed -i "" "s/^xdebug\.mode=.*/xdebug.mode=$mode/" "$ini"
            done
            herd restart >/dev/null 2>&1
            print "xdebug: $mode"
          }
        fi

        [ -f "$HOME/.secrets" ] && source "$HOME/.secrets"
        [ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

        function _paste-from-normal-mode() {
          zle vi-insert
          zle .bracketed-paste
        }
        zle -N _paste-from-normal-mode
        bindkey -M vicmd '^[[200~' _paste-from-normal-mode
      '';
    };
  };
}
