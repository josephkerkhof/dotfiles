{
  inputs,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.workstation
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.homestar-console
    age
    blueutil
    cloudflared
    coreutils-prefixed
    curl
    doctl
    docker-client
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
    mysql84
    nodejs
    osv-scanner
    pkgs."poppler-utils"
    ripgrep
    silver-searcher-ng
    switchaudio-osx
    (texliveSmall.withPackages (ps:
      with ps; [
        fontspec
        geometry
        tools
        xcolor
      ]))
    tree
    tree-sitter
    wget
    yt-dlp
  ];

  programs.gh.enable = true;
}
