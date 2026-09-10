# Personal Canary Cutover

The personal cutover is intentionally immediate: nix-darwin activation and
destructive removal of duplicate owners happen in one guarded script. The work
Mac is deferred.

## Preconditions

- Time Machine has completed a current backup to `tm-kerkhof`.
- The `nix` branch is clean, pushed, and checked out at `~/dotfiles`.
- SSH authentication can fetch the private `nix-private-assets` repository.
- The App Store is signed in so `mas` can verify the declared applications.
- The Mac is connected to power and has working network access.
- Ghostty has App Management permission if macOS requests it during activation.
- Review `scripts/cutover-personal.sh`; it intentionally removes packages and
  mutable state.

## Execute

Run the script as the normal user, not through `sudo`:

```sh
./scripts/cutover-personal.sh --execute
```

The script performs these stages:

1. Verify the host, branch, clean worktree, Stow links, reviewed Homebrew state,
   application paths, and Time Machine destination.
2. Require an explicit current-backup confirmation.
3. Record the Git revision and Homebrew inventories under
   `~/.local/state/nix-cutover`.
4. Run all flake checks, including the private input, and create the
   `result-personal` recovery GC root.
5. Adopt approved third-party app bundles as Homebrew casks, replacing the three
   bundles that cannot be adopted safely in place.
6. Remove Stow links, set the first nix-darwin system profile, and activate it.
7. Validate the Nix-owned shell, Neovim, Git, GPG, OpenCode, Ghostty, and
   LazyGit.
8. Stop obsolete services and remove approved Homebrew formulae, obsolete apps
   and casks, Rustup, Bun, MySQL data, and mutable Neovim installers.
9. Verify the retained casks and App Store IDs and confirm removed commands no
   longer resolve.

Do not remove `result-personal` or run Nix garbage collection until the canary is
accepted.

## Fix Forward

The selected recovery policy is fix-forward, not restoration of Stow and
Homebrew. If the login shell is broken, configure Ghostty temporarily to launch
`/bin/bash --noprofile --norc`, then use:

```sh
export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/joseph/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin"
cd ~/dotfiles
/nix/var/nix/profiles/default/bin/nix build path:.#darwinConfigurations.personal.system --out-link result-personal
system_path=$(readlink result-personal)
sudo /nix/var/nix/profiles/default/bin/nix-env --profile /nix/var/nix/profiles/system --set "$system_path"
sudo "$system_path/activate"
```

If the current checkout cannot build, reset only migration changes known to be
bad or check out a previously validated commit, then repeat the commands above.
The pre-cutover Time Machine backup remains the last-resort full-machine recovery
path.
