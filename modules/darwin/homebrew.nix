{username, ...}: {
  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = username;

    # Adopt the existing /opt/homebrew installation during canary cutover.
    autoMigrate = true;
    mutableTaps = true;
  };

  homebrew = {
    enable = true;
    enableZshIntegration = true;

    casks = [
      "bruno"
      "caffeine"
      "codex"
      "font-hack-nerd-font"
      "ghostty"
      "ngrok"
      "vlc"
    ];

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };
  };
}
