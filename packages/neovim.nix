{pkgs}: let
  inherit (pkgs) lib vimPlugins;

  configPlugin = pkgs.vimUtils.buildVimPlugin {
    pname = "joseph-neovim-config";
    version = "1";
    # These modules configure sibling plugins and cannot be required in isolation.
    nvimSkipModules = [
      "custom.plugins.init"
      "custom.plugins.autopairs"
      "custom.plugins.dap"
      "custom.plugins.gitsigns"
      "custom.plugins.neo-tree"
      "custom.plugins.neotest"
      "custom.plugins.opencode"
      "custom.plugins.render-markdown"
      "custom.plugins.vim-test"
    ];
    src = lib.fileset.toSource {
      root = ../nvim/.config/nvim;
      fileset = lib.fileset.unions [
        ../nvim/.config/nvim/colors
        ../nvim/.config/nvim/lua
        ../nvim/.config/nvim/spell
      ];
    };
  };

  pintPhar = pkgs.fetchurl {
    url = "https://github.com/laravel/pint/releases/download/v1.32.1/pint.phar";
    hash = "sha256-ivhdlMS2raHZAJn/HyvDLiyIU4ZJRzI2cZxRnGnjTl8=";
  };

  pint = pkgs.writeShellScriptBin "pint" ''
    exec ${pkgs.php}/bin/php ${pintPhar} "$@"
  '';

  php-debug-adapter = pkgs.writeShellScriptBin "php-debug-adapter" ''
    exec ${pkgs.nodejs}/bin/node ${pkgs.vscode-extensions.xdebug.php-debug}/share/vscode/extensions/xdebug.php-debug/out/phpDebug.js "$@"
  '';

  editorTools = with pkgs; [
    curl
    delve
    git
    go
    gomodifytags
    gopls
    gotests
    gotools
    impl
    lazygit
    lsof
    lua-language-server
    opencode
    php-debug-adapter
    pkgs."phpantom-lsp"
    pint
    prettier
    pyright
    ripgrep
    ruff
    stylua
    tree-sitter
    vscode-js-debug
    vtsls
    vue-language-server
    yaml-language-server
  ];

  treesitter = vimPlugins.nvim-treesitter.withPlugins (grammars:
    with grammars; [
      bash
      blade
      c
      diff
      go
      gomod
      gosum
      gowork
      html
      json
      lua
      luadoc
      markdown
      markdown_inline
      php
      phpdoc
      query
      vim
      vimdoc
      yaml
    ]);
in
  pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
    autoconfigure = false;
    wrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      (lib.makeBinPath editorTools)
    ];
    plugins = with vimPlugins; [
      configPlugin
      guess-indent-nvim
      which-key-nvim
      plenary-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      telescope-ui-select-nvim
      nvim-web-devicons
      nvim-lspconfig
      fidget-nvim
      conform-nvim
      blink-cmp
      luasnip
      tokyonight-nvim
      todo-comments-nvim
      mini-nvim
      treesitter
      auto-session
      toggleterm-nvim
      nvim-autopairs
      nvim-dap
      nvim-nio
      nvim-dap-ui
      nvim-dap-virtual-text
      nvim-dap-go
      gitsigns-nvim
      neo-tree-nvim
      nui-nvim
      neotest
      FixCursorHold-nvim
      neotest-golang
      opencode-nvim
      render-markdown-nvim
      vim-test
    ];
    luaRcContent = ''
      vim.g.nix_nvim_config = '${configPlugin}'
      vim.g.js_debug_adapter = 'js-debug'
      vim.g.vue_typescript_plugin_path = '${pkgs.vue-language-server}/lib/language-tools/packages/typescript-plugin'
      ${builtins.readFile ../nvim/.config/nvim/init.lua}
    '';
  }
