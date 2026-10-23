{pkgs}:
pkgs.stdenvNoCC.mkDerivation {
  pname = "opencode";
  version = "2.1.4";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@opencode/cli-darwin-arm64/-/cli-darwin-arm64-2.1.4.tgz";
    hash = "sha256-2qL+BPJ4hQkNzK7tng1lFLyAp4ScywqdlFIbODhRv6U=";
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
