-- neo-tree: persistent project-structure sidebar (the JetBrains Project
-- window). Devicons per filetype and git-status-tinted filenames by default.
---@module 'lazy'
---@type LazySpec
return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    filesystem = {
      -- Track the active buffer, JetBrains autoscroll-from-source style.
      follow_current_file = { enabled = true },
      -- Show dotfiles; keep .git itself out of the tree.
      filtered_items = {
        hide_dotfiles = false,
        never_show = { '.git' },
      },
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
