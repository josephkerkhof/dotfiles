{username, ...}: {
  imports = [
    ./config-files.nix
    ./ghostty.nix
    ./git.nix
    ./neovim.nix
    ./opencode.nix
    ./packages.nix
    ./shell.nix
    ./ssh.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
  xdg.enable = true;
}
