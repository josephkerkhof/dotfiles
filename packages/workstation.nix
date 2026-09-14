{pkgs}:
pkgs.stdenvNoCC.mkDerivation {
  pname = "workstation";
  version = "1.0.0";

  dontUnpack = true;

  nativeBuildInputs = with pkgs; [
    installShellFiles
    makeWrapper
    shellcheck
  ];

  buildPhase = ''
    runHook preBuild
    shellcheck ${./workstation.sh}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 ${./workstation.sh} "$out/bin/workstation"
    patchShebangs "$out/bin/workstation"
    wrapProgram "$out/bin/workstation" \
      --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.bash pkgs.coreutils pkgs.jq]}
    installShellCompletion --zsh ${./workstation.zsh}

    runHook postInstall
  '';

  meta = {
    description = "Human-friendly manager for nix-darwin workstation systems";
    mainProgram = "workstation";
    platforms = pkgs.lib.platforms.darwin;
  };
}
