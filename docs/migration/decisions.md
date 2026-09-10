# Migration Decisions

Decisions for the personal Mac canary. Work Mac inventory and policy are
deferred until the personal configuration is stable.

## Workstation Tools

- Berkeley Mono: install the licensed font declaratively from the private
  `josephkerkhof/nix-private-assets` flake input. Do not add the font files to
  the public dotfiles repository.
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
- Homebrew dnsmasq: remove the stopped installation during cutover. Herd retains
  temporary ownership of local routing until the project-environment migration.
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
- Global Composer path: remove the stale `~/.composer/vendor/bin` entry. Herd
  retains temporary Composer ownership; Composer later moves to project devenv
  environments.
- TeX: remove the nonexistent TinyTeX PATH entry and uninstall the global
  `mactex-no-gui` cask during cutover. TeX distributions belong to project
  devenv environments.
