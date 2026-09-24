{
  inputs,
  lib,
  pkgs,
  username,
  ...
}: {
  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["claude-code"];
  };

  networking.hostName = "Active-Engagement-MacBook-Pro";

  fonts.packages = [inputs.private-assets.packages.${pkgs.stdenv.hostPlatform.system}.berkeley-mono];

  homebrew = {
    casks = [
      "1password"
      "brave-browser"
      "claude"
      "discord"
      "docker-desktop"
      "elgato-control-center"
      "google-chrome"
      "linear-linear"
      "slack"
      "soundsource"
      "steam"
    ];
    brews = ["mas"];
    masApps = {
      "1Password for Safari" = 1569813296;
      iMovie = 408981434;
      Keynote = 361285480;
      Numbers = 361304891;
      Pages = 361309726;
      "Pixelmator Pro" = 1289583905;
      Wipr = 1662217862;
    };
  };

  home-manager.users.${username}.imports = [
    ./home.nix
    inputs.private-assets.homeModules.work
  ];

  environment.systemPackages = [];
}
