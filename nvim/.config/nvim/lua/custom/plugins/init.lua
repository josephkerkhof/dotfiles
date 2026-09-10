require('auto-session').setup {
  auto_save = true,
  auto_restore = true,
  close_filetypes_on_save = { 'checkhealth', 'neo-tree' },
  cwd_change_handling = false,
  suppressed_dirs = {
    '/',
    '~/Downloads',
  },
}

require('toggleterm').setup {
  open_mapping = '<leader>tt',
  direction = 'float',
}

vim.keymap.set(
  'n',
  '<leader>lg',
  function()
    require('toggleterm.terminal').Terminal
      :new({
        cmd = 'lazygit',
        direction = 'float',
      })
      :toggle()
  end,
  { desc = '[L]azy[G]it' }
)
