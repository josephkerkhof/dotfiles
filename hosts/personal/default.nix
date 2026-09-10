{...}: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "Josephs-MacBook-Pro";

  # Host-specific packages and preferences belong here as they are discovered.
  environment.systemPackages = [];
}
