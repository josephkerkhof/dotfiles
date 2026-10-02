{
  inputs,
  pkgs,
  ...
}: let
  # RustRover expects the rust-src component layout: <root>/library/<crate>.
  rustSrc = pkgs.runCommand "rust-src" {} ''
    mkdir -p $out
    cp -r ${pkgs.rustPlatform.rustLibSrc} $out/library
  '';
in {
  home = {
    packages = [
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.mov2web
      pkgs.awscli2
      pkgs.bun
      pkgs.cargo
      pkgs.claude-code
      pkgs.ipmitool
      pkgs.pnpm
      pkgs.rustc
      pkgs.rustfmt
    ];

    sessionVariables.RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    file.".local/share/rust-src" = {
      source = rustSrc;
      recursive = true;
    };
  };

  programs.zsh = {
    shellAliases = {
      ae = "cd ~/code/ae";
      sail = "sh $([ -f sail ] && echo sail || echo vendor/bin/sail)";
    };

    # Laravel Herd (work only) maintains ~/.zshrc with its PATH and per-PHP-version
    # ini vars. ZDOTDIR bypasses that file, so source it here.
    initContent = ''
      [ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc"
    '';
  };

  workstation.obs = {
    display = "B9513351-D18D-4F08-B10C-64FDA5708EFD";
    camera = "544FF7BF-5F9F-4376-B3D1-B69A00000001";
  };
}
