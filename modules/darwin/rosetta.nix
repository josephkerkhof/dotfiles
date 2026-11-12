{
  lib,
  pkgs,
  ...
}: {
  # Apple distributes Rosetta through softwareupdate, not as a Nix package.
  # Declare its installation here for the shared Colima VZ/Rosetta runtime.
  # Activation runs as root and stops on failure. Accepting Apple's license
  # is intentional; subsequent activations skip an already-working install.
  system.activationScripts.extraActivation.text = lib.mkIf pkgs.stdenv.hostPlatform.isAarch64 (lib.mkBefore ''
    if ! /usr/bin/arch -x86_64 /usr/bin/true >/dev/null 2>&1; then
      echo "installing Rosetta for the shared Homestar console..."
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license
      if ! /usr/bin/arch -x86_64 /usr/bin/true >/dev/null 2>&1; then
        echo "Rosetta installation did not enable Intel execution; activation cannot continue." >&2
        exit 1
      fi
    fi
  '');
}
