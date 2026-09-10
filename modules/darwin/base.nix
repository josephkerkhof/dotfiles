{
  inputs,
  username,
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
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {inherit inputs username;};
    users.${username} = import ../home;
  };
}
