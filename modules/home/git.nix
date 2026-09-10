{pkgs, ...}: {
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    enableZshIntegration = true;
    pinentry.package = pkgs.pinentry_mac;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      core.editor = "nvim";
      push.autoSetupRemote = true;
      user.useConfigOnly = true;
    };
  };
}
