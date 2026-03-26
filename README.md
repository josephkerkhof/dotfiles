# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) and [git subtree](https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging#_subtree_merge).

## Setup

### Prerequisites

- git
- [GNU Stow](https://www.gnu.org/software/stow/): `brew install stow`
- [Neovim](https://neovim.io/) (>= 0.10)

### Installation

```sh
git clone git@github.com:josephkerkhof/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Remove any existing configs that would conflict (e.g., `~/.config/nvim`), then stow the packages you want:

```sh
stow nvim
```

This creates a symlink from `~/.config/nvim` to `~/dotfiles/nvim/.config/nvim`.

To stow multiple packages at once:

```sh
stow nvim zsh tmux
```

### Unstowing

To remove the symlinks for a package:

```sh
stow -D nvim
```

## Syncing Neovim with upstream kickstart.nvim

The Neovim config is based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim), added via `git subtree`. Custom configuration lives in `lua/custom/plugins/` to minimize merge conflicts.

### Pull latest upstream changes

```sh
cd ~/dotfiles
git subtree pull --prefix nvim/.config/nvim https://github.com/nvim-lua/kickstart.nvim.git master --squash
```

If there are merge conflicts, resolve them as you would with any git merge, then commit.
