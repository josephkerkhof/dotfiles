# Repository Guidance for Assistants

## Scope and Current State

- This repository declares Joseph's macOS workstation with Determinate Nix,
  nix-darwin, Home Manager, nix-homebrew, and a private font flake.
- `darwinConfigurations.personal` is the active Apple Silicon canary.
- `darwinConfigurations.work` is only a scaffold. Do not activate it or infer
  work policy until the user explicitly inventories that machine.
- `scripts/cutover-personal.sh` is a completed one-time migration tool, not an
  ongoing state-management command. Do not run it again unless the user
  explicitly requests migration recovery work.
- Files under `docs/migration/` record the cutover and may describe historical
  pre-cutover state. Current Nix modules are authoritative for ongoing state.
- Keep `result-personal` and avoid garbage collection until the user explicitly
  accepts the canary.

## Ownership Boundaries

| Concern                                      | Owner               | Primary source                                              |
| -------------------------------------------- | ------------------- | ----------------------------------------------------------- |
| Flake inputs and outputs                     | Nix flake           | `flake.nix`, `flake.lock`                                   |
| Shared Darwin behavior                       | nix-darwin          | `modules/darwin/base.nix`                                   |
| Shared casks and Homebrew policy             | nix-darwin/Homebrew | `modules/darwin/homebrew.nix`                               |
| Personal apps, identity, fonts, and defaults | Personal host       | `hosts/personal/default.nix`, `modules/darwin/defaults.nix` |
| User CLI packages                            | Home Manager        | `modules/home/packages.nix`                                 |
| Shell, Git, GPG, and managed config files    | Home Manager        | `modules/home/*.nix`                                        |
| Neovim package, plugins, parsers, and tools  | Nix                 | `packages/neovim.nix`                                       |
| Neovim behavior                              | Packaged source     | `nvim/.config/nvim/`                                        |
| Project runtimes and services                | Project devenv      | Outside this workstation profile                            |

Homebrew is limited to declared casks and the `mas` formula. Most casks are GUI
applications; Codex, ngrok, and the font cask are existing explicit exceptions.
Do not add workstation CLI tools through Homebrew when a Nix package is
suitable.
`homebrew.onActivation.cleanup` is `"none"`, so removing a cask declaration
does not uninstall the application automatically. Treat app removal as a
separate, explicit, user-approved action.

Host-local mutable state must stay outside the Nix store. This includes secrets,
GPG keyrings, application data, credentials, project dependencies, Steam game
data, and the optional `~/.secrets` file. Never add secret material to this
repository or interpolate it into a Nix derivation.

## Active and Legacy Paths

- `ghostty/.config/ghostty/config` is active through Home Manager.
- Tracked files under `opencode/.config/opencode/` are linked individually so
  OpenCode can retain mutable state in the same config directory.
- `nvim/.config/nvim/` is active as source for the wrapped Nix Neovim package.
- The root `Brewfile` describes the legacy pre-cutover package set. Do not run
  `brew bundle` from it; doing so would reinstall removed workstation tools.
- Root `zsh/`, `git/`, and `lazygit/` content is retained Stow-era material and
  is not the active configuration. Change the corresponding Home Manager module
  instead unless the user explicitly asks to maintain migration history.

## Change Rules

- Add shared CLI packages to `modules/home/packages.nix`.
- Add an app used only on the personal Mac to the Homebrew block in
  `hosts/personal/default.nix`.
- Add a genuinely cross-host cask to `modules/darwin/homebrew.nix`.
- Add Mac App Store applications by ID to `homebrew.masApps` in the host module.
- Keep language runtimes, databases, and services project-scoped through
  devenv unless the user explicitly changes that policy. The global Go
  toolchain and its editor tooling are an existing exception.
- Preserve the existing public personal Git identity and host-local private GPG
  key ownership.
- Do not make the work scaffold activatable as a side effect of personal work.

## Build and Activation

Evaluate and build as the normal user. The private `private-assets` input uses
SSH, and evaluating the flake under `sudo` may not have access to the user's SSH
agent.

```sh
nix fmt
nix flake check path:. --print-build-logs
nix build path:.#darwinConfigurations.personal.system --out-link result-personal
```

Activation requires root and consists of both switching the system profile and
running the built activation program:

```sh
system_path=$(readlink -f result-personal)
sudo -H /nix/var/nix/profiles/default/bin/nix-env \
  --profile /nix/var/nix/profiles/system --set "$system_path"
sudo -H "$system_path/activate"
```

Do not claim activation succeeded until all three paths resolve to the same
store output:

```sh
readlink -f result-personal
readlink -f /nix/var/nix/profiles/system
readlink -f /run/current-system
```

For a shell-related change, also test a clean login environment so an old
terminal application's inherited environment cannot hide startup behavior:

```sh
/usr/bin/env -i \
  HOME="$HOME" USER="$USER" LOGNAME="$USER" SHELL=/bin/zsh \
  TERM=xterm-256color PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  /bin/zsh -lic exit
```

## Verification

- Run `nix fmt` after changing Nix files and inspect any formatter changes.
- Run `nix flake check path:. --print-build-logs` for configuration changes.
- Run `bash -n scripts/cutover-personal.sh` only when that historical script is
  edited.
- Run `git diff --check` before committing.
- Treat activation as a separate live-system verification step. Confirm the
  relevant command, app, setting, or managed file after activation.
- Do not garbage-collect as part of routine verification during canary
  evaluation.

## Rollback and Safety

- Use `sudo -H /run/current-system/sw/bin/darwin-rebuild --list-generations` to
  inspect generations.
- Use `sudo -H /run/current-system/sw/bin/darwin-rebuild --rollback` to switch
  to and activate the previous generation only after confirming it is a
  validated post-cutover generation.
- A generation rollback does not roll back the Git checkout or `flake.lock`.
- A generation rollback restores only Nix-managed state. It cannot restore apps,
  package data, services, or other mutable state deleted during the cutover; use
  the documented fix-forward recovery policy for cutover failures.
- Never delete mutable application data merely because an application or Nix
  package is removed.
- Never use the migration script, legacy `Brewfile`, work configuration, or
  garbage collection as a convenience shortcut.
