# Repository Guidance for Assistants

## Scope and Current State

- This repository declares Joseph's macOS workstation with Determinate Nix,
  nix-darwin, Home Manager, nix-homebrew, and a private assets flake.
- `darwinConfigurations.personal` is the personal Apple Silicon system
  (Josephs-MacBook-Pro).
- `darwinConfigurations.work` is the work Apple Silicon system
  (Active-Engagement-MacBook-Pro), enrolled in Rippling MDM.
- Work-private state (the AE Git identity for `~/code/ae/`, work SSH hosts)
  lives in the private assets flake as `homeModules.work`. Never add it here.

## Ownership Boundaries

| Concern                                      | Owner               | Primary source                                              |
| -------------------------------------------- | ------------------- | ----------------------------------------------------------- |
| Flake inputs and outputs                     | Nix flake           | `flake.nix`, `flake.lock`                                   |
| Shared Darwin behavior                       | nix-darwin          | `modules/darwin/*.nix`                                      |
| Shared casks and Homebrew policy             | nix-darwin/Homebrew | `modules/darwin/homebrew.nix`                               |
| Shared macOS defaults and security           | nix-darwin          | `modules/darwin/defaults.nix`                               |
| Shared Git identity and GPG signing          | Home Manager        | `modules/home/git.nix`                                      |
| Personal apps and fonts                      | Personal host       | `hosts/personal/default.nix`                                |
| Personal user configuration                  | Home Manager        | `hosts/personal/home.nix`                                   |
| Work apps, fonts, and Homebrew migration     | Work host           | `hosts/work/default.nix`                                    |
| Work user packages and aliases               | Home Manager        | `hosts/work/home.nix`                                       |
| Work-private Git include and SSH hosts       | Private assets      | `homeModules.work` in `nix-private-assets`                  |
| User CLI packages                            | Home Manager        | `modules/home/packages.nix`                                 |
| Shell, Git, GPG, SSH, and managed files      | Home Manager        | `modules/home/*.nix`                                        |
| Neovim package, plugins, parsers, and tools  | Nix                 | `packages/neovim.nix`                                       |
| Neovim behavior                              | Packaged source     | `nvim/.config/nvim/`                                        |
| Project runtimes and services                | Project devenv      | Outside this workstation profile                            |
| Workstation lifecycle utility                | Nix/Home Manager    | `packages/workstation.*`, `modules/home/packages.nix`       |
| Screen-recording converter (work)            | Nix/Home Manager    | `packages/mov2web.*`, `hosts/work/home.nix`                 |
| OBS screencast scenes and profile            | Home Manager        | `modules/home/obs.nix`, `hosts/*/home.nix`                  |

Homebrew is limited to declared casks and the `mas` formula. Most casks are GUI
applications; Codex, ngrok, and the font cask are existing explicit exceptions.
Do not add workstation CLI tools through Homebrew when a Nix package is
suitable.
MakeMKV is an imperative personal exception: nixpkgs supports it only on Linux,
and Homebrew disabled its macOS cask because it does not pass Gatekeeper.
Homebrew and its official taps are pinned by `flake.lock`; activation upgrades
installed packages from those pinned definitions without updating taps.
`homebrew.onActivation.cleanup` is `"none"`, so removing a cask declaration
does not uninstall the application automatically. Treat app removal as a
separate, explicit, user-approved action.
On the work Mac, Rippling MDM, UniFi Endpoint, Zoom, and internal app builds
such as Capsule stay unmanaged. Never declare them. `claude-code` is unfree; the work
host allows it by name with `allowUnfreePredicate`. Extend that list rather
than enabling all unfree packages.

Host-local mutable state must stay outside the Nix store. This includes secrets,
GPG keyrings, application data, credentials, project dependencies, Steam game
data, and the optional `~/.secrets` file. Never add secret material to this
repository or interpolate it into a Nix derivation.
Private infrastructure metadata belongs in the private assets flake: the
`homestar` modules for both hosts, `homeModules.work` for the work Mac only.
SSH keys, `known_hosts`, agent state, and `~/.ssh/config.local`
remain host-local and mutable.

## Active Paths

- Ghostty is installed through Homebrew and configured through Home Manager.
- OBS is installed through Homebrew. Home Manager copies the generated
  `Screencast` scene collection and profile into the OBS config directory on
  every activation, so edits to that collection do not persist. Per-host
  display, camera, and microphone IDs live in `hosts/*/home.nix`.
- OpenCode is installed and configured through Home Manager. Its managed rule,
  command, and theme sources coexist with mutable state in its config directory.
- `nvim/.config/nvim/` is active as source for the wrapped Nix Neovim package.
- `~/.ssh/config` is generated by Home Manager and includes the mutable
  `~/.ssh/config.local` file.
- `/etc/hosts` is generated by nix-darwin. Its public baseline is in
  `modules/darwin/hosts.nix`; private mappings come from the private assets flake.
- OpenCode automatic LSP downloads are disabled. Add workstation language
  servers through Home Manager or keep project-specific tools in devenv.

## Change Rules

- Add shared CLI packages to `modules/home/packages.nix`.
- Add personal-only Home Manager state to `hosts/personal/home.nix` and
  work-only state to `hosts/work/home.nix`.
- Add an app used only on one Mac to the Homebrew block of that host module.
- Add a genuinely cross-host cask to `modules/darwin/homebrew.nix`.
- Add Mac App Store applications by ID to `homebrew.masApps` in the host module.
- Keep language runtimes, databases, and services project-scoped through
  devenv unless the user explicitly changes that policy. Three exceptions are
  global: the Go toolchain with its editor tooling, Node.js, which Claude Code
  MCP servers launch through `npx`, and the MySQL client tools (`mysql` and
  `mysqlsh`) for connecting to remote databases.
- Preserve the shared public Git identity in `modules/home/git.nix`, the private
  AE include for `~/code/ae/`, and host-local private GPG key ownership.
- `nix-homebrew.autoMigrate` is `false`. A Mac with an installer-based
  `/opt/homebrew` needs `lib.mkForce true` in its host module for the first
  activation only, with the old `Library/Taps` moved aside. Remove the
  override after that activation.
- Treat `modules/darwin` and `modules/home` as cross-host configuration. Move
  state there only after confirming that both hosts should inherit it.
- Do not change one host as a side effect of work on the other.

## Build and Activation

Evaluate and build as the normal user. The private `private-assets` input uses
SSH, and evaluating the flake under `sudo` may not have access to the user's SSH
agent.

The human-facing `workstation` command wraps this workflow, infers a target from
its declared hostname, and refuses cross-host activation. Its implementation
must preserve the underlying privilege and verification boundaries below.

```sh
nix fmt -- .
nix flake check path:. --print-build-logs
nix build path:.#darwinConfigurations.<workstation>.system --out-link result-<workstation>
```

The nixpkgs input resolves through FlakeHub; `nix flake update nixpkgs` follows
the newest FlakeHub `0.2605` revision and may change nothing.

Activation requires root and consists of both switching the system profile and
running the built activation program. Successful activation retains the newest
five system generations:

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

- Run `nix fmt -- .` after changing Nix files and inspect any formatter changes.
- Run `nix flake check path:. --print-build-logs` for configuration changes.
- Run `git diff --check` before committing.
- Treat activation as a separate live-system verification step. Confirm the
  relevant command, app, setting, or managed file after activation.
- Keep garbage collection separate from routine activation and verification.

## Rollback and Safety

- Use `sudo -H /run/current-system/sw/bin/darwin-rebuild --list-generations` to
  inspect generations.
- Use `sudo -H /run/current-system/sw/bin/darwin-rebuild --rollback` to switch
  to and activate the previous generation only after confirming it is a
  known-good generation.
- A generation rollback does not roll back the Git checkout or `flake.lock`.
- A generation rollback restores only Nix-managed state. It cannot restore apps,
  package data, services, or other mutable state.
- Never delete mutable application data merely because an application or Nix
  package is removed.
- Successful activation automatically prunes system generations older than the
  newest five. Run garbage collection only as an intentional maintenance
  operation.
