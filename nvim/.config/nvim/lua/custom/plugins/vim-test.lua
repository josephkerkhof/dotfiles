-- vim-test: run the nearest / current / whole Pest suite in a toggleterm float.
-- A maintained, lightweight alternative to a neotest adapter -- real pest
-- output, no discovery cost, no dead APIs. Works for any language vim-test
-- supports; Go still goes through neotest-golang (<leader>n*).
-- vim-test ships no toggleterm strategy, so register one that pipes the
-- command through toggleterm.exec into a dedicated terminal (#9).
vim.cmd [[
      function! ToggleTermStrategy(cmd) abort
        call luaeval("require('toggleterm').exec(_A[1], _A[2])", [a:cmd, 9])
      endfunction
      let g:test#custom_strategies = {'toggleterm': function('ToggleTermStrategy')}
    ]]
vim.g['test#strategy'] = 'toggleterm'
-- Herd runs php natively, so each project's own binary is correct.
vim.g['test#php#pest#executable'] = 'vendor/bin/pest'

-- Nearest/file are inherently file-anchored. Run these from a test buffer.
vim.keymap.set('n', '<leader>Tn', '<cmd>TestNearest<cr>', { desc = '[T]est [N]earest' })
vim.keymap.set('n', '<leader>Tf', '<cmd>TestFile<cr>', { desc = '[T]est [F]ile' })
vim.keymap.set('n', '<leader>Tl', '<cmd>TestLast<cr>', { desc = '[T]est [L]ast' })
-- Suite is project-level, so it works from any buffer.
vim.keymap.set('n', '<leader>Ts', function() require('toggleterm').exec('./vendor/bin/pest --parallel', 9) end, { desc = '[T]est [S]uite (parallel)' })
