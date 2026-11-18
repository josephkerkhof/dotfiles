{
  inputs,
  lib,
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
      "chatgpt"
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
      WireGuard = 1451685025;
      Xcode = 497799835;
    };
  };

  # Xcode supplies Simulator. Install its iOS runtime after Homebrew Bundle.
  system.activationScripts.postActivation.text = lib.mkBefore ''
    (
      xcode_developer_dir=/Applications/Xcode.app/Contents/Developer
      if [ ! -x "$xcode_developer_dir/usr/bin/xcodebuild" ]; then
        echo "Xcode is missing after Homebrew Bundle." >&2
        exit 1
      fi

      if ! DEVELOPER_DIR="$xcode_developer_dir" /usr/bin/xcodebuild -checkFirstLaunchStatus; then
        echo "Complete Xcode's first-launch setup, then run workstation apply again to install the iOS simulator runtime." >&2
        exit 0
      fi

      xcode_user=${lib.escapeShellArg username}
      xcode_uid="$(/usr/bin/id -u "$xcode_user")"
      xcode_as_user() {
        /bin/launchctl asuser "$xcode_uid" /usr/bin/sudo --user="$xcode_user" --set-home \
          /usr/bin/env DEVELOPER_DIR="$xcode_developer_dir" "$@"
      }

      ios_runtime_available() {
        xcode_as_user /usr/bin/xcrun simctl list -j runtimes |
          ${lib.getExe pkgs.jq} 'any(.runtimes[]; .isAvailable and (.identifier | startswith("com.apple.CoreSimulator.SimRuntime.iOS-")))'
      }

      available="$(ios_runtime_available)"
      if [ "$available" != true ]; then
        echo "Installing the iOS simulator runtime..." >&2
        xcode_as_user /usr/bin/xcodebuild -downloadPlatform iOS
        available="$(ios_runtime_available)"
        if [ "$available" != true ]; then
          echo "Xcode did not report an available iOS simulator runtime after installation." >&2
          exit 1
        fi
      fi
    )
  '';

  home-manager.users.${username}.imports = [./home.nix];

  # Host-specific packages and preferences belong here as they are discovered.
  environment.systemPackages = [];
}
