{
  config,
  inputs,
  username,
  ...
}: {
  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;
    user = username;

    autoMigrate = false;
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
  };

  homebrew = {
    enable = true;
    enableZshIntegration = false;
    taps = builtins.attrNames config.nix-homebrew.taps;

    casks = [
      "bruno"
      "caffeine"
      "font-hack-nerd-font"
      "ghostty"
      "intellij-idea"
      "ngrok"
      "obs"
      "vlc"
    ];

    onActivation = {
      autoUpdate = false;
      upgrade = true;
      cleanup = "none";
    };
  };
}
