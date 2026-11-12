{config, ...}: {
  # Copy real app bundles, rather than store symlinks, so Spotlight can index them.
  targets.darwin.copyApps.enable = true;
  assertions = [
    {
      assertion = config.xdg.configFile ? "homestar-console/connection.json";
      message = "homestar-console requires non-secret connection.json from private-assets homeModules.homestar; update the private-assets pin.";
    }
  ];
  services.colima = {
    enable = true;
    colimaHomeDir = ".config/colima";
    profiles.homestar-console = {
      isService = false;
      isActive = false;
      setDockerHost = false;
      mutableSettings = true;
      settings = import ../../packages/homestar-console/settings.nix;
    };
  };
}
