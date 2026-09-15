# macOS Workstation

This repository is the source of truth for Joseph's macOS workstation. It uses
Determinate Nix, nix-darwin, Home Manager, nix-homebrew, and a private assets
flake.

Two Apple Silicon hosts are declared: `personal` (Josephs-MacBook-Pro) and
`work` (Active-Engagement-MacBook-Pro). The `workstation` command selects the
configuration from the current hostname.

## How The System Is Organized

| What                     | Managed by          | Where to change it            |
| ------------------------ | ------------------- | ----------------------------- |
| Flake dependencies       | Nix                 | `flake.nix`, `flake.lock`     |
| Shared macOS behavior    | nix-darwin          | `modules/darwin/*.nix`        |
| macOS preferences        | nix-darwin          | `modules/darwin/defaults.nix` |
| Personal apps and fonts  | nix-darwin/Homebrew | `hosts/personal/default.nix`  |
| Personal user settings   | Home Manager        | `hosts/personal/home.nix`     |
| Work apps and fonts      | nix-darwin/Homebrew | `hosts/work/default.nix`      |
| Work user packages       | Home Manager        | `hosts/work/home.nix`         |
| Work-private Git and SSH | Private assets      | `homeModules.work` (private)  |
| Shared Homebrew casks    | nix-darwin/Homebrew | `modules/darwin/homebrew.nix` |
| Command-line tools       | Home Manager        | `modules/home/packages.nix`   |
| Shell, Git, GPG, and SSH | Home Manager        | `modules/home/*.nix`          |
| Ghostty                  | Home Manager/Brew   | `modules/home/ghostty.nix`    |
| OpenCode                 | Home Manager        | `modules/home/opencode.nix`   |
| Neovim package and tools | Nix                 | `packages/neovim.nix`         |
| Neovim behavior          | Neovim source       | `nvim/.config/nvim/`          |
| Workstation utility      | Nix/Home Manager    | `packages/workstation.*`      |
| Screen-recording convert | Nix/Home Manager    | `packages/mov2web.*`          |

The ownership rule is:

- Files under `modules/darwin` and `modules/home` are shared by every declared
  host. Host-specific system and user state belongs under `hosts/<name>`.
- Nix owns workstation command-line tools and managed configuration.
- Homebrew owns declared casks and the single `mas` formula. Most casks are GUI
  apps; Codex, ngrok, and the font cask are current exceptions. Homebrew and its
  official taps are pinned by `flake.lock`.
- Project runtimes, databases, and services generally belong in each project's
  devenv. Two workstation exceptions: the Go toolchain, and Node.js for MCP
  servers that Claude Code starts through `npx`.
- Secrets, credentials, GPG keys, application data, and game data remain local
  mutable state.
- The public Git identity is shared by both hosts in `modules/home/git.nix`.
  The work identity for `~/code/ae/` is a conditional include from the private
  assets flake.
- Private connection metadata comes from the private assets flake: the
  `homestar` modules for both hosts, the `work` home module for the work Mac
  only. SSH keys, `known_hosts`, and host-local entries remain under `~/.ssh`.
- On the work Mac, Rippling MDM, UniFi Endpoint, Zoom, and internal app builds
  stay unmanaged.
- MakeMKV remains an imperative personal installation because nixpkgs supports
  it only on Linux and Homebrew disabled its macOS cask for failing Gatekeeper.

## Apply A Change

The `workstation` command guides the normal test and activation workflow. It
infers the current workstation from the Mac's hostname, explains each step, and
asks before changing the running system:

```sh
cd ~/dotfiles
workstation apply
```

Keep testing and activation separate when you want to inspect the candidate
first:

```sh
workstation test
workstation status
workstation activate
```

Use the built-in help for workflows, examples, and the safety behavior of each
command:

```sh
workstation help
workstation help activate
workstation list
```

Pass a workstation explicitly to test a different declared configuration. Both
option forms are accepted:

```sh
workstation test --workstation=personal
workstation --workstation personal test
```

Cross-workstation testing is allowed, but activation is refused unless the
configuration's declared hostname matches the current Mac.

Before the utility has been activated for the first time, run the packaged
version directly from the checkout:

```sh
nix run path:.#workstation -- apply
```

### What the utility does

`workstation test` captures one immutable source snapshot, runs the
repository-wide flake checks against it, and builds the selected configuration
into `result-<workstation>`. It evaluates and builds as the normal user so the
private SSH flake input remains accessible.

`workstation activate` resolves that exact candidate, shows the current and
candidate store paths, asks for confirmation, and then runs the established
profile selection and activation commands:

```sh
system_path=$(readlink -f result-personal)
sudo -H /nix/var/nix/profiles/default/bin/nix-env \
  --profile /nix/var/nix/profiles/system --set "$system_path"
sudo -H "$system_path/activate"
```

Activation applies macOS, Homebrew, Home Manager, and user configuration. It
then verifies that the candidate, selected system profile, and running system
all resolve to the same store path. Successful activation retains the newest
five system generations and removes older generation links.

Test the command, application, or preference you changed before committing the
result.

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
devenv instead. Go with its editor tools and Node.js for `npx`-launched MCP
servers are the explicit global exceptions.

### Add a GUI application

- Add a personal-only cask to `hosts/personal/default.nix`.
- Add a work-only cask to `hosts/work/default.nix`.
- Add a genuinely shared cask to `modules/darwin/homebrew.nix`.
- Add an App Store application and its numeric ID to `homebrew.masApps` in the
  host module.

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

- Edit `modules/home/opencode.nix` for OpenCode settings and dependencies.
- Edit `opencode/.config/opencode/` for managed rule, command, and theme sources.

Automatic OpenCode language-server downloads are disabled. Language servers
must come from Nix or the current project's devenv. Credentials, caches, and
session data remain mutable outside the Nix store.

### Change SSH

- Edit `modules/home/ssh.nix` for public SSH client policy.
- Edit the private assets flake for private host definitions: `homestar` for
  both hosts, `work` for the work Mac only.
- Edit `~/.ssh/config.local` for host-local entries.

Home Manager owns `~/.ssh/config`. Private keys, `known_hosts`, agent state, and
the included local configuration remain mutable and must not enter this public
repository or a Nix derivation.

### Change the hosts file

- Edit `modules/darwin/hosts.nix` for the public macOS hosts-file baseline.
- Edit the private assets flake for private address mappings.

nix-darwin owns `/etc/hosts`. Do not edit it directly after activation.

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

Determinate Nix resolves the nixpkgs input through FlakeHub. The lock follows
the newest FlakeHub `0.2605` revision, which can lag the GitHub branch by days.
An update that changes nothing means FlakeHub has not advanced.

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

Keep `result-<workstation>` as the current candidate build. Successful activation
automatically retains the newest five system generations, providing bounded
rollback history. This does not garbage-collect unreferenced store paths.

Use the guided garbage-collection command:

```sh
workstation gc
```

It lists retained generations, previews machine-wide store garbage, and asks
before collecting anything. `workstation gc --yes` still performs the preview
but skips the final confirmation. Garbage collection is not scoped by
`--workstation` and remains separate from normal activation or verification. It
never replaces backups for mutable application data, credentials, project
state, or game data.

## Fresh Mac

1. Install the Xcode Command Line Tools and Determinate Nix.
2. Sign in to the App Store.
3. Restore the host-local GPG key and configure SSH access to GitHub and the
   private `nix-private-assets` repository.
4. Clone this repository to `~/dotfiles`.
5. Run the normal check, build, and activation workflow above. The utility
   selects `personal` or `work` from the hostname.

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
