# dotfiles

Declarative macOS workstation configuration built with nix-darwin, Home
Manager, and Determinate Nix. Nix owns command-line tools and configuration;
nix-darwin uses Homebrew only for GUI applications and `mas` for App Store
applications.

## Hosts

- `personal`: primary Apple Silicon personal Mac profile.
- `work`: scaffold only; inventory and activation are deferred until the
  personal canary is stable.

Project runtimes and services belong in project `devenv.sh` environments rather
than the workstation profile.

## Fresh Personal Mac

1. Install the Xcode Command Line Tools and Determinate Nix.
2. Sign into the App Store, restore the host-local GPG signing key, and configure
   SSH access to GitHub, including the private `nix-private-assets` repository.
3. Clone this repository at `~/dotfiles` and build the personal system:

```sh
git clone git@github.com:josephkerkhof/dotfiles.git ~/dotfiles
cd ~/dotfiles
/nix/var/nix/profiles/default/bin/nix flake check path:.
/nix/var/nix/profiles/default/bin/nix build path:.#darwinConfigurations.personal.system --out-link result-personal
system_path=$(readlink result-personal)
sudo /nix/var/nix/profiles/default/bin/nix-env --profile /nix/var/nix/profiles/system --set "$system_path"
sudo "$system_path/activate"
```

The existing personal Mac has a stricter one-time migration procedure in
[`docs/migration/personal-cutover.md`](docs/migration/personal-cutover.md).

## Syncing Neovim with upstream kickstart.nvim

The Neovim config is based on
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim), added through a
Git subtree. Custom configuration lives in `lua/custom/plugins/` to minimize
merge conflicts. Plugins, parsers, language servers, formatters, and debug
adapters are packaged by Nix rather than installed at runtime.

### Pull latest upstream changes

```sh
cd ~/dotfiles
git subtree pull --prefix nvim/.config/nvim https://github.com/nvim-lua/kickstart.nvim.git master --squash
```

If there are merge conflicts, resolve them as you would with any git merge, then commit.
