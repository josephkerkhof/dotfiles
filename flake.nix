{
  description = "Joseph's macOS workstation configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    private-assets = {
      url = "git+ssh://git@github.com/josephkerkhof/nix-private-assets.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nix-darwin,
    home-manager,
    determinate,
    nix-homebrew,
    ...
  }: let
    username = "joseph";

    mkDarwin = hostModule:
      nix-darwin.lib.darwinSystem {
        specialArgs = {inherit inputs username;};
        modules = [
          determinate.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          ./modules/darwin/base.nix
          ./modules/darwin/homebrew.nix
          hostModule
        ];
      };
  in {
    darwinConfigurations.personal = mkDarwin ./hosts/personal;
    darwinConfigurations.work = mkDarwin ./hosts/work;

    packages.aarch64-darwin.neovim = import ./packages/neovim.nix {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
    };

    checks.aarch64-darwin.neovim = self.packages.aarch64-darwin.neovim;
    checks.aarch64-darwin.personal = self.darwinConfigurations.personal.system;
    checks.aarch64-darwin.work = self.darwinConfigurations.work.system;
    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
  };
}
