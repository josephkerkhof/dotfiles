-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

---@module 'lazy'
---@type LazySpec
return {
  {
    'rmagatti/auto-session',
    lazy = false,
    opts = {},
  },
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {
      open_mapping = '<leader>tt',
      direction = 'float',
    },
    keys = {
      { '<leader>tt', desc = '[T]oggle [T]erminal' },
    },
  },
}
