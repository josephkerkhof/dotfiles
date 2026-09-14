_: {
  home = {
    sessionVariables = {
      EDITOR = "nvim";
      OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
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
      completionInit = ''
        mkdir -p "$XDG_CACHE_HOME/zsh"
        autoload -U compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
      '';
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

        [ -f "$HOME/.secrets" ] && source "$HOME/.secrets"
        function _paste-from-normal-mode() {
          zle vi-insert
          zle .bracketed-paste
        }
        zle -N _paste-from-normal-mode
        bindkey -M vicmd '^[[200~' _paste-from-normal-mode

        # devenv auto-activation
        eval "$(devenv hook zsh)"
      '';
    };
  };
}
