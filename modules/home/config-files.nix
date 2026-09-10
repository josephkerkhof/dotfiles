{
  programs.lazygit = {
    enable = true;
    settings.os.editPreset = "nvim-remote";
  };

  xdg.configFile = {
    "ghostty/config".source = ../../ghostty/.config/ghostty/config;

    "opencode/opencode.jsonc".source = ../../opencode/.config/opencode/opencode.jsonc;
    "opencode/tui.jsonc".source = ../../opencode/.config/opencode/tui.jsonc;
    "opencode/commands/openai-usage.md".source = ../../opencode/.config/opencode/commands/openai-usage.md;
    "opencode/rules/asd-ste100.md".source = ../../opencode/.config/opencode/rules/asd-ste100.md;
    "opencode/themes/islands-dark.json".source = ../../opencode/.config/opencode/themes/islands-dark.json;
    "opencode/scripts/openai-usage" = {
      source = ../../opencode/.config/opencode/scripts/openai-usage;
      executable = true;
    };
  };
}
