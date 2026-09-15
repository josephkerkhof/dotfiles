{
  inputs,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.workstation
    age
    blueutil
    cloudflared
    coreutils-prefixed
    curl
    devenv
    doctl
    fastfetch
    ffmpeg
    glow
    go
    gomodifytags
    gopls
    gotests
    gotools
    impl
    jq
    kubectl
    kubernetes-helm
    osv-scanner
    pkgs."poppler-utils"
    ripgrep
    silver-searcher-ng
    switchaudio-osx
    tree
    tree-sitter
    wget
    yt-dlp
  ];

  programs.gh.enable = true;
}
