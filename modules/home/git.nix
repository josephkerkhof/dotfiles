{
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      core.editor = "nvim";
      push.autoSetupRemote = true;
      user.useConfigOnly = true;
    };

    includes = [
      {path = "~/.gitconfig.local";}
      {
        condition = "gitdir:~/code/ae/";
        path = "~/.gitconfig-ae.local";
      }
    ];
  };
}
