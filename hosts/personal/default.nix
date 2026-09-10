{
  inputs,
  pkgs,
  ...
}: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "Josephs-MacBook-Pro";

  fonts.packages = [inputs.private-assets.packages.${pkgs.stdenv.hostPlatform.system}.berkeley-mono];

  # Host-specific packages and preferences belong here as they are discovered.
  environment.systemPackages = [];
}
