{
  inputs,
  pkgs,
  username,
  ...
}: {
  imports = [../../modules/darwin/defaults.nix];

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

  home-manager.users.${username}.programs.git.settings = {
    user = {
      name = "Joseph Kerkhof";
      email = "joseph@kerkhof.dev";
      signingKey = "51C7FCE5909B5D1F80813F0671A696CAC91CEA76";
    };
    commit.gpgSign = true;
  };

  # Host-specific packages and preferences belong here as they are discovered.
  environment.systemPackages = [];
}
