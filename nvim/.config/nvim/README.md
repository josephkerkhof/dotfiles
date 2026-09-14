# Neovim Config

Personal Neovim config managed from `~/dotfiles`.

## Shape

- `init.lua` holds core editor options, LSP, completion, formatting, Telescope, Treesitter, and theme setup.
- `lua/custom/plugins/` contains direct setup for the larger plugin integrations.
- `packages/neovim.nix` owns Neovim, plugins, Treesitter parsers, language servers, formatters, and debug adapters.

## Common Commands

```sh
nix build path:.#neovim --out-link result-neovim
./result-neovim/bin/nvim
./result-neovim/bin/nvim --headless '+checkhealth' '+qa'
```

Inside Neovim:

- `:ConformInfo` shows formatter state.

Plugin and tool updates happen through `flake.lock` and `packages/neovim.nix`; the editor does not download them at runtime.
