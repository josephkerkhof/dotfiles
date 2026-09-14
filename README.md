# macOS Workstation

This repository is the source of truth for Joseph's macOS workstation. It uses
Determinate Nix, nix-darwin, Home Manager, nix-homebrew, and a private font
flake.

The `personal` configuration is the active Apple Silicon system. No work-host
output is exported; that configuration will be added only after the machine is
inventoried.

## How The System Is Organized

| What                       | Managed by          | Where to change it                               |
| -------------------------- | ------------------- | ------------------------------------------------ |
| Flake dependencies         | Nix                 | `flake.nix`, `flake.lock`                        |
| Shared macOS behavior      | nix-darwin          | `modules/darwin/base.nix`                        |
| macOS preferences          | nix-darwin          | `modules/darwin/defaults.nix`                    |
| Personal apps and fonts    | nix-darwin/Homebrew | `hosts/personal/default.nix`                     |
| Shared Homebrew casks      | nix-darwin/Homebrew | `modules/darwin/homebrew.nix`                    |
| Command-line tools         | Home Manager        | `modules/home/packages.nix`                      |
| Shell, Git, and GPG        | Home Manager        | `modules/home/shell.nix`, `modules/home/git.nix` |
| Ghostty and OpenCode files | Home Manager        | `modules/home/config-files.nix`                  |
| Neovim package and tools   | Nix                 | `packages/neovim.nix`                            |
| Neovim behavior            | Neovim source       | `nvim/.config/nvim/`                             |

The ownership rule is:

- Nix owns workstation command-line tools and managed configuration.
- Homebrew owns declared casks and the single `mas` formula. Most casks are GUI
  apps; Codex, ngrok, and the font cask are current exceptions. Homebrew and its
  official taps are pinned by `flake.lock`.
- Project runtimes, databases, and services generally belong in each project's
  devenv. The workstation Go toolchain is a current exception.
- Secrets, credentials, GPG keys, application data, and game data remain local
  mutable state.

## Apply A Change

Run evaluation and builds as your normal user. The flake fetches a private input
over SSH, which may not work when Nix evaluates it as root.

### 1. Format and check

After editing Nix files:

```sh
cd ~/dotfiles
nix fmt -- .
nix flake check path:. --print-build-logs
```

`nix flake check` evaluates and builds the personal system and packaged Neovim.
It does not activate anything.

### 2. Build the personal system

```sh
nix build path:.#darwinConfigurations.personal.system \
  --out-link result-personal
```

Building updates the `result-personal` symlink but does not change the running
system.

### 3. Activate the build

```sh
system_path=$(readlink -f result-personal)
sudo -H /nix/var/nix/profiles/default/bin/nix-env \
  --profile /nix/var/nix/profiles/system --set "$system_path"
sudo -H "$system_path/activate"
```

The first command selects the system generation. The second applies macOS,
Homebrew, Home Manager, and user configuration. After activation succeeds, the
system profile retains the newest five generations and removes older generation
links.

### 4. Confirm what is running

```sh
readlink -f result-personal
readlink -f /nix/var/nix/profiles/system
readlink -f /run/current-system
```

All three commands should print the same `/nix/store/...-darwin-system-...`
path. Test the command, application, or preference you changed before committing
the result.

For shell changes, test without environment inherited from an old terminal
process:

```sh
/usr/bin/env -i \
  HOME="$HOME" USER="$USER" LOGNAME="$USER" SHELL=/bin/zsh \
  TERM=xterm-256color PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  /bin/zsh -lic exit
```

## Common Changes

### Add or remove a command-line tool

Edit `modules/home/packages.nix`, then follow the normal check, build, and
activation workflow.

Do not install workstation CLI tools with Homebrew when a suitable Nix package
exists. Language runtimes and databases should usually be added to a project's
devenv instead; Go and its editor tools are currently installed globally as an
explicit exception.

### Add a GUI application

- Add a personal-only cask to `hosts/personal/default.nix`.
- Add a genuinely shared cask to `modules/darwin/homebrew.nix`.
- Add an App Store application and its numeric ID to `homebrew.masApps` in the
  personal host module.

Activation installs missing declared applications. The App Store must already
be signed in for `mas` applications. Existing Homebrew packages are upgraded
from the revisions pinned in `flake.lock`; Homebrew does not update taps on its
own.

### Remove a GUI application

Remove its declaration and activate the new system, then uninstall the app
separately after confirming that its mutable data should be retained or removed.

Homebrew cleanup is deliberately set to `"none"`. Removing a cask from Nix does
not automatically uninstall the application or delete its data.

### Change macOS preferences

Edit `modules/darwin/defaults.nix`. Activation may restart affected macOS
components such as the Dock.

Not every preference is managed. For example, Dock pins are currently left to
macOS, so manually removing a stale Dock icon remains effective after future
activations.

### Change Neovim

- Edit `nvim/.config/nvim/` for editor behavior.
- Edit `packages/neovim.nix` for plugins, parsers, language servers, formatters,
  and debug adapters.
- Build only Neovim with `nix build path:.#neovim` for a focused package check.

Neovim does not use Lazy, Mason, or runtime Treesitter downloads. Its runtime
dependencies are part of the Nix package.

### Change OpenCode

- Edit `opencode/.config/opencode/` for managed OpenCode behavior.
- Add shared formatters and language servers to `modules/home/packages.nix`.

Automatic OpenCode language-server downloads are disabled. Language servers
must come from Nix or the current project's devenv. Credentials, caches, and
session data remain mutable outside the Nix store.

## Update Nix Dependencies

Update all inputs recorded in `flake.lock`:

```sh
cd ~/dotfiles
nix flake update
nix flake check path:. --print-build-logs
```

Update one input, such as nixpkgs:

```sh
nix flake update nixpkgs
```

Review the `flake.lock` diff, build, activate, and test before committing an
update. Updating inputs can change many packages at once even when no module was
edited. Updating `homebrew-core` or `homebrew-cask` also changes the package
definitions used by Homebrew during the next activation.

## Inspect And Roll Back

List system generations:

```sh
sudo -H /run/current-system/sw/bin/darwin-rebuild --list-generations
```

After confirming the previous entry is a known-good generation, switch to and
activate it:

```sh
sudo -H /run/current-system/sw/bin/darwin-rebuild --rollback
```

A generation rollback restores Nix-managed configuration only. It does not
restore applications, services, package data, or other mutable state.

Rollback also does not change the Git checkout or `flake.lock`. Fix or revert
the repository separately before the next normal activation.

To inspect the selected and running systems directly:

```sh
readlink -f /nix/var/nix/profiles/system
readlink -f /run/current-system
```

## Store Maintenance

Keep `result-personal` as the current candidate build. Successful activation
automatically retains the newest five system generations, providing bounded
rollback history. This does not garbage-collect unreferenced store paths.

Before collecting the store, inspect the retained generations and potential
garbage:

```sh
sudo -H /run/current-system/sw/bin/darwin-rebuild --list-generations
nix store gc --dry-run
```

Garbage collection is a separate maintenance operation, not part of normal
activation or verification. It never replaces backups for mutable application
data, credentials, project state, or game data.

## Fresh Personal Mac

1. Install the Xcode Command Line Tools and Determinate Nix.
2. Sign in to the App Store.
3. Restore the host-local GPG key and configure SSH access to GitHub and the
   private `nix-private-assets` repository.
4. Clone this repository to `~/dotfiles`.
5. Run the normal check, build, and activation workflow above.

## Sync Neovim With kickstart.nvim

The Neovim configuration is based on
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) and tracked as a
Git subtree. Custom modules live under `lua/custom/plugins/` to reduce merge
conflicts. A subtree pull creates a commit, so perform it on a temporary branch:

```sh
cd ~/dotfiles
git switch -c update/kickstart
git subtree pull \
  --prefix nvim/.config/nvim \
  https://github.com/nvim-lua/kickstart.nvim.git master --squash
```

Resolve conflicts before continuing. Review the resulting commit for any plugin
or tool installation performed at runtime, including Lazy, Mason, `vim.pack`, or
Treesitter downloads. Represent required dependencies in `packages/neovim.nix`
instead.

Build the package and test startup with isolated mutable state:

```sh
nix build path:.#neovim --out-link result-neovim
test_home=$(mktemp -d)
HOME="$test_home" \
  XDG_CONFIG_HOME="$test_home/config" \
  XDG_DATA_HOME="$test_home/data" \
  XDG_STATE_HOME="$test_home/state" \
  XDG_CACHE_HOME="$test_home/cache" \
  ./result-neovim/bin/nvim --headless \
  -c 'lua assert(vim.fn.exists(":Lazy") == 0); assert(vim.fn.exists(":Mason") == 0)' \
  -c qa
rm -rf "$test_home"
nix flake check path:. --print-build-logs
```

The startup assertion covers the known mutable package managers; review is what
catches new mechanisms added upstream. After the checks pass, fast-forward the
`nix` branch to the reviewed update and delete the temporary branch.
