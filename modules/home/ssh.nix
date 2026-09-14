{inputs, ...}: {
  imports = [inputs.private-assets.homeModules.homestar];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = ["~/.ssh/config.local"];

    extraOptionOverrides = {
      IgnoreUnknown = "UseKeychain";
      UseKeychain = true;
    };

    settings."*" = {
      AddKeysToAgent = "yes";
      Compression = false;
      HashKnownHosts = true;
      ServerAliveCountMax = 3;
      ServerAliveInterval = 60;
      UserKnownHostsFile = "~/.ssh/known_hosts";
    };
  };
}
