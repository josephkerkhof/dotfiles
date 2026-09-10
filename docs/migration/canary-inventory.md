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

Host-local identity and secret files remain outside the repository:

- `~/.gitconfig.local`
- `~/.gitconfig-ae.local`
- `~/.secrets`
- `~/.zshrc.local`
- `~/.local/share/opencode/auth.json`

## Mutable Tool Owners

- Homebrew owns the current CLI and GUI package set.
- Lazy owns Neovim plugins.
- Mason owns Neovim language servers, formatters, and debug adapters.
- Runtime Treesitter installation owns Neovim parsers.
- Herd owns PHP 8.2 through 8.5, its NVM integration, local routing, TLS, and
  mutable Xdebug configuration.
- Cargo, Bun, Composer, and TinyTeX contribute additional user-local tools.

These owners remain in place while the Nix closure is built and tested. The
canary cutover must remove Stow links and duplicate workstation tool owners as a
single coordinated operation. Herd and project data are explicitly excluded
from that cleanup phase.

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

## Pre-Cutover Neovim

The Stow link still loads `nvim/.config/nvim/init.lua` in the Homebrew editor.
Until the coordinated cutover removes that link, the config adds the existing
Lazy plugin checkouts to `runtimepath` without invoking Lazy or downloading
updates. The Nix-wrapped editor does not use this compatibility path.
