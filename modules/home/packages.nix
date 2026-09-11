{pkgs, ...}: {
  home.packages = with pkgs; [
    age
    blueutil
    coreutils-prefixed
    devenv
    doctl
    fastfetch
    ffmpeg
    git-lfs
    glow
    go
    gomodifytags
    gopls
    gotests
    gotools
    htop
    impl
    jq
    jujutsu
    kubectl
    kubernetes-helm
    opencode
    osv-scanner
    pkgs."poppler-utils"
    prettier
    pkgs."phpantom-lsp"
    ripgrep
    ruff
    silver-searcher-ng
    stylua
    switchaudio-osx
    tree
    tree-sitter
    wget
    yt-dlp
  ];

  programs.gh.enable = true;
}
