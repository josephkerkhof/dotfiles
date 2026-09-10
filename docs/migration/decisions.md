# Migration Decisions

Decisions for the personal Mac canary. Work Mac inventory and policy are
deferred until the personal configuration is stable.

## Workstation Tools

- Berkeley Mono: install the licensed font declaratively from the private
  `josephkerkhof/nix-private-assets` flake input. Do not add the font files to
  the public dotfiles repository.
- Fonts: retain the declarative Hack Nerd Font cask and remove the duplicate
  plain `font-hack` cask during cutover.
- Third-party GUI apps: adopt and declare Homebrew casks for balenaEtcher,
  Discord, Logos, Raspberry Pi Imager, Signal, Steam, and Telegram on the
  personal host. MakeMKV remains a manual exception because Homebrew disabled
  its cask after it failed Gatekeeper validation. Remove the Sparrow, IntelliJ
  IDEA, and Zoom app bundles during cutover while preserving their user data and
  settings.
- Mac App Store: declare GarageBand, iMovie, Keynote, Numbers, Pages, Pixelmator
  Pro, and Wipr by App Store ID. Retain Homebrew `mas` as the sole formula leaf
  needed for App Store ownership.
- Application leftovers: remove the stale `/Applications/X-Plane` alias and
  `/Applications/Output` support directory during cutover.
- Terraform: remove during cutover without replacing it with OpenTofu. Remove
  the `hashicorp/tap` Homebrew tap when no remaining package uses it.
- Node.js, Node 22, pnpm, npm, and the globally installed Wrangler package:
  remove during cutover. JavaScript runtimes and Wrangler belong to individual
  project environments through devenv. Workstation applications that use Node
  must carry their own Nix runtime dependencies.
- Homebrew MySQL 8.4: back up `/opt/homebrew/var/mysql`, then remove the stopped
  service and formula during cutover. Future databases belong to project devenv
  environments.
- Homebrew Temporal: remove the stopped global installation during cutover.
  Temporal CLI and server versions belong to project devenv environments.
- Homebrew RoadRunner: remove the global binary during cutover. RoadRunner
  versions belong to project devenv environments.
- Homebrew `act`: remove during cutover without replacement.
- Homebrew Cloudflared: unregister the stale failing launch agent and remove the
  CLI during cutover without replacement.
- Homebrew dnsmasq: remove the stopped installation during cutover. Local
  routing returns only through future project devenv environments.
- Homebrew `golang-migrate`: remove during cutover without a workstation-level
  replacement.
- Homebrew Hugo: remove during cutover and pin Hugo in each relevant project
  devenv.
- Homebrew `libpq` and its PostgreSQL client commands: remove during cutover
  without a workstation-level replacement.
- Homebrew Pandoc: remove during cutover and pin Pandoc in each relevant project
  devenv.
- Rustup and the user-local Rust toolchain: remove during cutover and stop
  sourcing `~/.cargo/env`. Rust toolchains belong to project devenv environments.
- Bun: remove the dormant shell hook from the target configuration and delete
  the stale `~/.bun` installer directory during cutover. Future Bun versions
  belong to project devenv environments.
- Global Composer path: remove the stale `~/.composer/vendor/bin` entry.
  Composer belongs to future project devenv environments.
- TeX: remove the nonexistent TinyTeX PATH entry and uninstall the global
  `mactex-no-gui` cask during cutover. TeX distributions belong to project
  devenv environments.
- Gemini CLI: remove from both Nix and Homebrew without replacing it with
  Antigravity CLI.
- Herd: remove all dormant shell integration and Herd-based aliases. Herd, PHP,
  and Composer are already absent; those runtimes and services return only
  through future project devenv environments.
- Laravel Sail: remove the global shell alias. Project commands belong to
  future devenv tasks.
- Local executable path: remove the empty `~/.local/bin` directory from global
  PATH. Workstation commands must be Nix-owned; project commands belong to
  devenv.
- Zsh local override: remove the dormant `.zshrc.local` hook. Host differences
  must be expressed through host modules.
- Shell secrets: retain the conditional `.secrets` hook as the host-local secret
  boundary. The file is currently absent and must never enter Git or the Nix
  store.
- Git identity: declare `Joseph Kerkhof <joseph@kerkhof.dev>` in the public
  personal host module. Remove the obsolete `.gitconfig.local` and
  `.gitconfig-ae.local` includes; work identity is deferred with the work Mac.
- Git signing: enable GPG commit signing with fingerprint
  `51C7FCE5909B5D1F80813F0671A696CAC91CEA76`. Nix owns GnuPG and pinentry while
  the private keyring remains mutable under `~/.gnupg` and is protected by Time
  Machine.

## macOS Defaults

- Dock: preserve auto-hide, 48 px tiles, grouped App Expose windows, and the
  top-left Mission Control hot corner. Leave pinned applications and directory
  stacks unmanaged.
- Finder: preserve list view as the default, show external and removable disks
  on the desktop, and hide the internal disk. Leave hidden files, extensions,
  path/status bars, sidebars, and window state unmanaged.
- Keyboard: preserve `InitialKeyRepeat=15` and `KeyRepeat=2`, disable
  press-and-hold, and disable automatic capitalization, spelling correction,
  smart quotes/dashes, and double-space periods.
- Trackpad: preserve tap-to-click, two-finger secondary click, and three-finger
  drag. Leave sensitivity and other gestures unmanaged.
- Screenshots: save PNG files under `~/Pictures/Screenshots`, retain the preview
  thumbnail, and disable window shadows. Home Manager creates the destination.
- Security: enable Touch ID and Apple Watch authentication for `sudo`, with the
  normal password fallback. Enable the macOS application firewall while allowing
  signed applications; do not enable stealth or block-all mode. Keep FileVault
  manually managed; it is currently on.

## Cutover Policy

- Backup gate: require a current Time Machine backup. Do not create a separate
  targeted archive.
- Perform activation and destructive cleanup in one coordinated maintenance
  window rather than retaining duplicate owners for a validation period.
- Recovery policy: fix forward from a macOS recovery shell and the Nix store;
  use Time Machine only as the last resort. Do not plan to reinstall the legacy
  Stow/Homebrew setup as the primary rollback.
- Cleanup execution: use one guarded, fail-fast script with explicit preflight
  and validation stages.
