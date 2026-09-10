{username, ...}: {
  imports = [
    ./config-files.nix
    ./git.nix
    ./neovim.nix
    ./packages.nix
    ./shell.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
  xdg.enable = true;
}
