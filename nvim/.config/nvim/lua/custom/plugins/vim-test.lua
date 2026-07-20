-- vim-test: run the nearest / current / whole Pest suite in a toggleterm float.
-- A maintained, lightweight alternative to a neotest adapter -- real pest
-- output, no discovery cost, no dead APIs. Works for any language vim-test
-- supports; Go still goes through neotest-golang (<leader>n*).
---@module 'lazy'
---@type LazySpec
return {
  'vim-test/vim-test',
  dependencies = { 'akinsho/toggleterm.nvim' },
  keys = {
    -- Nearest/file are inherently file-anchored -- use vim-test (its --filter
    -- for the nearest test is the whole point). Run these from a test buffer.
    { '<leader>Tn', '<cmd>TestNearest<cr>', desc = '[T]est [N]earest' },
    { '<leader>Tf', '<cmd>TestFile<cr>', desc = '[T]est [F]ile' },
    { '<leader>Tl', '<cmd>TestLast<cr>', desc = '[T]est [L]ast' },
    -- Suite is project-level, not file-anchored, so it goes straight to the
    -- toggleterm and works from any buffer -- mirroring how `art` runs.
    {
      '<leader>Ts',
      function() require('toggleterm').exec('./vendor/bin/pest --parallel', 9) end,
      desc = '[T]est [S]uite (parallel)',
    },
  },
  init = function()
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
  end,
}
