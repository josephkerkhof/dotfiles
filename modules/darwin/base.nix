{
  config,
  inputs,
  lib,
  username,
  workstationName,
  ...
}: {
  determinateNix.enable = true;

  system = {
    configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
    primaryUser = username;
    stateVersion = 6;
  };

  users.users.${username}.home = "/Users/${username}";

  programs.zsh = {
    enable = true;
    enableCompletion = false;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs username;};
    users.${username} = import ../home;
  };

  system.systemBuilderCommands = ''
    printf '%s' ${lib.escapeShellArg workstationName} > "$out/workstation-name"
    printf '%s' ${lib.escapeShellArg config.networking.hostName} > "$out/workstation-hostname"
  '';

  # Bound rollback history after a successful activation. Store garbage
  # collection remains a separate maintenance operation.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    generations_to_delete="$(
      for generation_link in /nix/var/nix/profiles/system-*-link; do
        generation="''${generation_link##*/system-}"
        printf '%s\n' "''${generation%-link}"
      done | /usr/bin/sort -rn | /usr/bin/tail -n +6
    )"

    if [ -n "$generations_to_delete" ]; then
      echo "removing system generations older than the newest five: $generations_to_delete"
      printf '%s\n' "$generations_to_delete" | /usr/bin/xargs \
        /nix/var/nix/profiles/default/bin/nix-env \
          --profile /nix/var/nix/profiles/system \
          --delete-generations
    fi
  '';
}
