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

    homebrew-core = {
      url = "github:Homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:Homebrew/homebrew-cask";
      flake = false;
    };

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

    mkDarwin = workstationName: hostModule:
      nix-darwin.lib.darwinSystem {
        specialArgs = {inherit inputs username workstationName;};
        modules = [
          determinate.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          ./modules/darwin/base.nix
          ./modules/darwin/hosts.nix
          ./modules/darwin/homebrew.nix
          ./modules/darwin/defaults.nix
          hostModule
        ];
      };
  in {
    darwinConfigurations.personal = mkDarwin "personal" ./hosts/personal;
    darwinConfigurations.work = mkDarwin "work" ./hosts/work;

    packages.aarch64-darwin = {
      neovim = import ./packages/neovim.nix {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      };
      openai-usage = import ./packages/openai-usage.nix {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      };
      mov2web = import ./packages/mov2web.nix {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      };
      workstation = import ./packages/workstation.nix {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      };
    };

    checks.aarch64-darwin = {
      mov2web = self.packages.aarch64-darwin.mov2web;
      neovim = self.packages.aarch64-darwin.neovim;
      openai-usage = self.packages.aarch64-darwin.openai-usage;
      neovim-startup =
        nixpkgs.legacyPackages.aarch64-darwin.runCommand "neovim-startup-check" {
          nativeBuildInputs = [self.packages.aarch64-darwin.neovim];
        } ''
          test_home="$TMPDIR/home"
          mkdir -p "$test_home"/{config,data,state,cache}
          HOME="$test_home" \
            XDG_CONFIG_HOME="$test_home/config" \
            XDG_DATA_HOME="$test_home/data" \
            XDG_STATE_HOME="$test_home/state" \
            XDG_CACHE_HOME="$test_home/cache" \
            nvim --headless \
              -c 'lua assert(vim.fn.exists(":Lazy") == 0); assert(vim.fn.exists(":Mason") == 0)' \
              -c qa
          touch "$out"
        '';
      nix-source =
        nixpkgs.legacyPackages.aarch64-darwin.runCommand "nix-source-check" {
          nativeBuildInputs = with nixpkgs.legacyPackages.aarch64-darwin; [
            alejandra
            statix
          ];
        } ''
          alejandra --check ${self}
          statix check ${self}
          touch "$out"
        '';
      opencode-config =
        nixpkgs.legacyPackages.aarch64-darwin.runCommand "opencode-config-check" {
          nativeBuildInputs = [nixpkgs.legacyPackages.aarch64-darwin.opencode];
        } ''
          test_home="$TMPDIR/home"
          mkdir -p "$test_home"/{config,data,state,cache}
          cp -R ${self.darwinConfigurations.personal.config.home-manager.users.${username}.home.activationPackage}/home-files/.config/opencode \
            "$test_home/config/opencode"
          chmod -R u+w "$test_home/config/opencode"
          HOME="$test_home" \
            XDG_CONFIG_HOME="$test_home/config" \
            XDG_DATA_HOME="$test_home/data" \
            XDG_STATE_HOME="$test_home/state" \
            XDG_CACHE_HOME="$test_home/cache" \
            OPENCODE_PURE=1 \
            opencode debug config >/dev/null
          touch "$out"
        '';
      personal = self.darwinConfigurations.personal.system;
      work = self.darwinConfigurations.work.system;
      workstation = self.packages.aarch64-darwin.workstation;
      workstation-cli =
        nixpkgs.legacyPackages.aarch64-darwin.runCommand "workstation-cli-check" {
          nativeBuildInputs = [self.packages.aarch64-darwin.workstation];
        } ''
          workstation --help >/dev/null
          workstation help activate >/dev/null
          workstation help gc >/dev/null
          test "$(cat ${self.darwinConfigurations.personal.system}/workstation-name)" = personal
          test "$(cat ${self.darwinConfigurations.personal.system}/workstation-hostname)" = Josephs-MacBook-Pro
          test "$(cat ${self.darwinConfigurations.work.system}/workstation-name)" = work
          test "$(cat ${self.darwinConfigurations.work.system}/workstation-hostname)" = Active-Engagement-MacBook-Pro
          if workstation test --yes 2>/dev/null; then
            echo "invalid test options unexpectedly succeeded" >&2
            exit 1
          fi
          if workstation gc --workstation=personal 2>/dev/null; then
            echo "workstation-scoped garbage collection unexpectedly succeeded" >&2
            exit 1
          fi
          if workstation unknown-command 2>/dev/null; then
            echo "unknown workstation command unexpectedly succeeded" >&2
            exit 1
          fi
          touch "$out"
        '';
    };
    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
  };
}
