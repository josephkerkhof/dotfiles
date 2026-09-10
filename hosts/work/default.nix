{...}: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  # The hostname and work-only policy will be added after inventorying this Mac.
  environment.systemPackages = [];
}
