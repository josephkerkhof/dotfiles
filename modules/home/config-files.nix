_: {
  programs.lazygit = {
    enable = true;
    settings.os.editPreset = "nvim-remote";
  };

  xdg.configFile."opencode/rules/asd-ste100.md".source =
    ../../opencode/.config/opencode/rules/asd-ste100.md;
}
