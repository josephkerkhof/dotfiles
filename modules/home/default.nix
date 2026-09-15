{
  lib,
  username,
  ...
}: {
  imports = [
    ./config-files.nix
    ./ghostty.nix
    ./git.nix
    ./neovim.nix
    ./opencode.nix
    ./packages.nix
    ./programs.nix
    ./shell.nix
    ./ssh.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "26.05";

    activation.createScreenshotDirectory = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p "$HOME/Pictures/Screenshots"
    '';
  };

  programs.home-manager.enable = true;
  xdg.enable = true;
}
