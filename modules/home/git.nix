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
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        commit.gpgSign = true;
        user = {
          name = "Joseph Kerkhof";
          email = "joseph@kerkhof.dev";
          signingKey = "51C7FCE5909B5D1F80813F0671A696CAC91CEA76";
          useConfigOnly = true;
        };
      };
    };
  };
}
