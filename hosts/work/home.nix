{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.mov2web
    pkgs.claude-code
  ];

  programs.zsh.shellAliases.ae = "cd ~/code/ae";

  workstation.obs = {
    display = "B9513351-D18D-4F08-B10C-64FDA5708EFD";
    camera = "544FF7BF-5F9F-4376-B3D1-B69A00000001";
  };
}
