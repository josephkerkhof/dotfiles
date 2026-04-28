# Neovim Config

Personal Neovim config managed from `~/dotfiles`.

## Shape

- `init.lua` holds core editor options, LSP, completion, formatting, Telescope, Treesitter, and theme setup.
- `lua/kickstart/plugins/` keeps the remaining extracted plugin specs from the original Kickstart base.
- `lua/custom/plugins/` is the personal overlay for plugins that are not part of the base.
- `lazy-lock.json` is tracked so plugin updates are explicit.

## Common Commands

```sh
nvim
nvim --headless '+checkhealth' '+qa'
```

Inside Neovim:

- `:Lazy` manages plugins.
- `:Mason` manages external tools.
- `:ConformInfo` shows formatter state.
