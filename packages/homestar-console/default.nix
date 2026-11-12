{pkgs}: let
  settings = pkgs.writeText "homestar-console-settings.json" (builtins.toJSON (import ./settings.nix));
in
  pkgs.stdenvNoCC.mkDerivation {
    pname = "homestar-console";
    version = "1.0.0";
    dontUnpack = true;
    nativeBuildInputs = [pkgs.makeWrapper pkgs.shellcheck];
    doCheck = true;
    checkPhase = ''
      shellcheck ${./startapp.sh}
      PYTHONDONTWRITEBYTECODE=1 ${pkgs.python3}/bin/python3 ${./test.py} ${./homestar-console.py}
    '';
    installPhase = ''
      install -Dm755 ${./homestar-console.py} "$out/bin/homestar-console"
      install -Dm644 ${./UPSTREAM-LICENSE} "$out/share/doc/homestar-console/UPSTREAM-LICENSE"
      substituteInPlace "$out/bin/homestar-console" \
        --replace-fail '@python@' '${pkgs.python3}/bin/python3' \
        --replace-fail '@settings@' '${settings}' \
        --replace-fail '@startapp@' '${./startapp.sh}'
      wrapProgram "$out/bin/homestar-console" \
        --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.colima pkgs.docker-client pkgs.openssh pkgs.curl pkgs.coreutils pkgs.perl pkgs.bash]}

      # Home Manager copies Applications bundles into ~/Applications for Spotlight.
      app="$out/Applications/Homestar Console.app"
      mkdir -p "$out/Applications"
      substitute ${./launcher.applescript} "$TMPDIR/launcher.applescript" \
        --subst-var-by launcher "$out/bin/homestar-console"
      /usr/bin/osacompile -o "$app" "$TMPDIR/launcher.applescript"
      ${pkgs.python3}/bin/python3 - "$app/Contents/Info.plist" <<'PY'
      import pathlib, plistlib, sys
      path = pathlib.Path(sys.argv[1])
      with path.open("rb") as stream:
          info = plistlib.load(stream)
      info.update({
          "CFBundleName": "Homestar Console",
          "CFBundleDisplayName": "Homestar Console",
          "CFBundleIdentifier": "com.josephkerkhof.homestar-console",
          "CFBundleShortVersionString": "1.0.0",
          "CFBundleVersion": "1",
          "LSUIElement": True,
          "NSLocalNetworkUsageDescription": "Connect to Homestar's iDRAC through the local console runtime.",
      })
      with path.open("wb") as stream:
          plistlib.dump(info, stream)
      assert (path.parent / "MacOS" / info["CFBundleExecutable"]).is_file()
      assert (path.parent / "Resources/Scripts/main.scpt").is_file()
      PY
    '';
    postFixup = ''
      /usr/bin/codesign --force --sign - --timestamp=none "$out/Applications/Homestar Console.app"
      /usr/bin/codesign --verify --deep --strict "$out/Applications/Homestar Console.app"
    '';
    meta = {
      description = "On-demand iDRAC 6 console in an isolated Colima profile";
      mainProgram = "homestar-console";
      platforms = ["aarch64-darwin"];
    };
  }
