# Neovim Config

Personal Neovim config managed from `~/dotfiles`.

## Shape

- `init.lua` holds core editor options, LSP, completion, formatting, Telescope, Treesitter, and theme setup.
- `lua/custom/plugins/` contains direct setup for the larger plugin integrations.
- `packages/neovim.nix` owns Neovim, plugins, Treesitter parsers, language servers, formatters, and debug adapters.
- `lazy-lock.json` is a legacy artifact and is not used by the Nix-owned editor.

## Common Commands

```sh
nix build path:.#neovim
./result/bin/nvim
./result/bin/nvim --headless '+checkhealth' '+qa'
```

Inside Neovim:

- `:ConformInfo` shows formatter state.

Plugin and tool updates happen through `flake.lock` and `packages/neovim.nix`; the editor does not download them at runtime.
