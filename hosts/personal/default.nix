{
  inputs,
  pkgs,
  username,
  ...
}: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "Josephs-MacBook-Pro";

  fonts.packages = [inputs.private-assets.packages.${pkgs.stdenv.hostPlatform.system}.berkeley-mono];

  homebrew = {
    casks = [
      "balenaetcher"
      "discord"
      "logos"
      "raspberry-pi-imager"
      "signal"
      "steam"
      "telegram"
    ];
    brews = ["mas"];
    masApps = {
      GarageBand = 682658836;
      iMovie = 408981434;
      Keynote = 361285480;
      Numbers = 361304891;
      Pages = 361309726;
      "Pixelmator Pro" = 1289583905;
      Wipr = 1662217862;
    };
  };

  home-manager.users.${username}.imports = [./home.nix];

  # Host-specific packages and preferences belong here as they are discovered.
  environment.systemPackages = [];
}
