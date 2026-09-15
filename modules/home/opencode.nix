{
  inputs,
  pkgs,
  ...
}: {
  programs.opencode = {
    enable = true;

    extraPackages = with pkgs; [
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.openai-usage
      bash-language-server
      gopls
      gotools
      lua-language-server
      pkgs."phpantom-lsp"
      prettier
      pyright
      ruff
      stylua
      vue-language-server
      yaml-language-server
    ];

    settings = {
      instructions = ["rules/asd-ste100.md"];

      lsp = {
        bash.command = [
          "bash-language-server"
          "start"
        ];
        gopls.command = ["gopls"];
        lua-ls.command = ["lua-language-server"];
        "php intelephense".disabled = true;
        phpantom = {
          extensions = [".php"];
          command = ["phpantom_lsp"];
        };
        pyright.command = [
          "pyright-langserver"
          "--stdio"
        ];
        vue.command = [
          "vue-language-server"
          "--stdio"
        ];
        yaml-ls.command = [
          "yaml-language-server"
          "--stdio"
        ];
      };

      formatter = {
        gofmt.command = [
          "goimports"
          "-w"
          "$FILE"
        ];
        prettier.command = [
          "prettier"
          "--write"
          "$FILE"
        ];
        ruff.disabled = true;
        ruff-organize-imports = {
          command = [
            "ruff"
            "check"
            "--select"
            "I"
            "--fix"
            "$FILE"
          ];
          extensions = [
            ".py"
            ".pyi"
          ];
        };
        ruff-format = {
          command = [
            "ruff"
            "format"
            "$FILE"
          ];
          extensions = [
            ".py"
            ".pyi"
          ];
        };
        stylua = {
          command = [
            "stylua"
            "$FILE"
          ];
          extensions = [".lua"];
        };
        clang-format.disabled = true;
      };
    };

    tui = {
      theme = "islands-dark";
      leader_timeout = 300;
      mouse = true;
      diff_style = "auto";
      attention = {
        enabled = true;
        notifications = true;
        sound = false;
      };
    };

    commands.openai-usage = ../../opencode/.config/opencode/commands/openai-usage.md;
    themes.islands-dark = ../../opencode/.config/opencode/themes/islands-dark.json;
  };
}
