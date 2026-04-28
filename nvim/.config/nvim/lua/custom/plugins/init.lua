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
    opts = {
      auto_save = true,
      auto_restore = true,
      cwd_change_handling = false,
      suppressed_dirs = {
        '/',
        '~/Downloads',
        vim.fn.stdpath 'data' .. '/lazy/*',
      },
    },
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
      {
        '<leader>lg',
        function()
          require('toggleterm.terminal').Terminal
            :new({
              cmd = 'lazygit',
              direction = 'float',
            })
            :toggle()
        end,
        desc = '[L]azy[G]it',
      },
    },
  },
}
