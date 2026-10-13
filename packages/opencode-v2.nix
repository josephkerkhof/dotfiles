{pkgs}:
pkgs.stdenvNoCC.mkDerivation {
  pname = "opencode";
  version = "2.0.28";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@opencode/cli-darwin-arm64/-/cli-darwin-arm64-2.0.28.tgz";
    hash = "sha256-PPIpzDrdHxyqd+V6J8mDTYF52/u2lPnzboat1rkrUSE=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    install -m755 bin/opencode "$out/bin/opencode"
    ln -s opencode "$out/bin/opencode2"

    runHook postInstall
  '';

  meta = {
    description = "AI coding agent built for the terminal";
    homepage = "https://opencode.ai";
    mainProgram = "opencode";
    platforms = ["aarch64-darwin"];
  };
}
