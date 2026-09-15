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
}
