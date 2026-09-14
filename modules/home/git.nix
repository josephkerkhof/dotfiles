{pkgs, ...}: {
  home = {
    packages = [pkgs.pinentry_mac];

    # Home Manager's Darwin service cannot pass launchd sockets to
    # gpg-agent's supervised mode, so let GnuPG start the agent on demand.
    file.".gnupg/gpg-agent.conf".text = ''
      grab
      pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
    '';
  };

  programs = {
    gpg.enable = true;

    zsh.initContent = ''
      export GPG_TTY=$TTY
    '';

    git = {
      enable = true;
      lfs.enable = true;

      settings = {
        core.editor = "nvim";
        push.autoSetupRemote = true;
        user.useConfigOnly = true;
      };
    };
  };
}
