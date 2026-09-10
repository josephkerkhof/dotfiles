# Personal Canary Inventory

Captured before the nix-darwin cutover. This document records ownership and
recovery-sensitive state, not secret values.

## Host

- Flake host: `personal`
- Local hostname: `Josephs-MacBook-Pro`
- Architecture: Apple Silicon (`aarch64-darwin`)
- Initial migration OS: macOS 26.6.2
- Nix: Determinate Nix 3.22.3, upstream compatibility version 2.35.2
- Nix installer self-test: passing

## Current Configuration Ownership

GNU Stow currently links these paths into the repository:

- `~/.zshenv`
- `~/.zshrc`
- `~/.gitconfig`
- `~/.config/ghostty`
- `~/.config/lazygit`
- `~/.config/nvim`

`~/.config/opencode` is a real directory containing mutable package and runtime
state. Home Manager must manage the tracked OpenCode files individually rather
than replace that directory.

The OpenCode credential database remains host-local under
`~/.local/share/opencode`. The target shell reserves `~/.secrets` as an optional
host-local secret boundary, but that file is currently absent. The former
`~/.gitconfig.local`, `~/.gitconfig-ae.local`, and `~/.zshrc.local` override
files are also absent and are not retained by the target configuration.

## Mutable Tool Owners

- Homebrew owns the current CLI and GUI package set.
- Lazy owns Neovim plugins.
- Mason owns Neovim language servers, formatters, and debug adapters.
- Runtime Treesitter installation owns Neovim parsers.
- Herd was present during the initial inventory but has since been removed,
  along with its PHP, Composer, NVM, routing, TLS, and Xdebug state.
- Rustup and stale Bun installer state remain installed. Global Composer and
  TinyTeX are absent.

The remaining owners stay in place while the Nix closure is built and tested.
The canary cutover must remove Stow links and duplicate workstation tool owners
as a single coordinated operation. Project runtimes will be added later through
devenv rather than preserving Herd.

## Homebrew State

The committed `Brewfile` declares 40 formulae, 7 casks, and 2 third-party taps.
The live installation also has manually installed roots, including `act`,
`cloudflared`, `dnsmasq`, `golang-migrate`, `hugo`, `libpq`, and `pandoc`, plus
the `font-hack` and `mactex-no-gui` casks.

Current services:

- `cloudflared`: registered as a user service but currently failing
- `dnsmasq`: installed but not running
- `mysql@8.4`: installed but not running through Homebrew services
- `temporal`: installed but not running through Homebrew services

The initial nix-darwin Homebrew policy uses `cleanup = "none"`. No undeclared
formula, cask, tap, service, or data directory may be removed during initial
activation.

## Target GUI Ownership

- Existing Homebrew casks retained by the shared profile: Bruno, Caffeine,
  Codex, Hack Nerd Font, Ghostty, ngrok, and VLC.
- Existing app bundles to be adopted as personal Homebrew casks: balenaEtcher,
  Discord, Logos, Raspberry Pi Imager, Signal, Steam, and Telegram. Cutover
  replaces the balenaEtcher, Raspberry Pi Imager, and Signal bundles when their
  existing artifacts cannot be adopted.
- MakeMKV remains manually installed because Homebrew disabled its cask after it
  failed Gatekeeper validation.
- App Store applications declared by ID: GarageBand, iMovie, Keynote, Numbers,
  Pages, Pixelmator Pro, and Wipr.
- App bundles to be removed while preserving user data: IntelliJ IDEA, Sparrow,
  and Zoom.
- Stale application leftovers to be removed: `/Applications/X-Plane` and
  `/Applications/Output`.
- Steam remains the mutable owner of game installations and launchers under
  `~/Applications`.

## Pre-Cutover Neovim

The Stow link still loads `nvim/.config/nvim/init.lua` in the Homebrew editor.
Until the coordinated cutover removes that link, the config adds the existing
Lazy plugin checkouts to `runtimepath` without invoking Lazy or downloading
updates. The Nix-wrapped editor does not use this compatibility path.
