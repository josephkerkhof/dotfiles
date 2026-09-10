local neotest = require 'neotest'

neotest.setup {
  adapters = {
    require 'neotest-golang' {
      dap_go_enabled = true,
    },
  },
}

vim.keymap.set('n', '<leader>nt', function() neotest.run.run() end, { desc = '[N]eotest nearest [T]est' })
vim.keymap.set('n', '<leader>nf', function() neotest.run.run(vim.fn.expand '%') end, { desc = '[N]eotest [F]ile' })
vim.keymap.set('n', '<leader>na', function() neotest.run.run(vim.uv.cwd()) end, { desc = '[N]eotest [A]ll' })
vim.keymap.set('n', '<leader>ns', neotest.summary.toggle, { desc = '[N]eotest [S]ummary' })
vim.keymap.set('n', '<leader>no', function() neotest.output.open { enter = true } end, { desc = '[N]eotest [O]utput' })
vim.keymap.set('n', '<leader>np', neotest.output_panel.toggle, { desc = '[N]eotest output [P]anel' })
vim.keymap.set('n', '<leader>nd', function() neotest.run.run { strategy = 'dap' } end, { desc = '[N]eotest [D]ebug nearest' })
vim.keymap.set('n', '<leader>nx', neotest.run.stop, { desc = '[N]eotest stop' })
