---@module 'lazy'
---@type LazySpec
return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    'fredrikaverpil/neotest-golang',
    'V13Axel/neotest-pest',
  },
  keys = {
    { '<leader>nt', function() require('neotest').run.run() end, desc = '[N]eotest nearest [T]est' },
    { '<leader>nf', function() require('neotest').run.run(vim.fn.expand '%') end, desc = '[N]eotest [F]ile' },
    { '<leader>na', function() require('neotest').run.run(vim.uv.cwd()) end, desc = '[N]eotest [A]ll' },
    { '<leader>ns', function() require('neotest').summary.toggle() end, desc = '[N]eotest [S]ummary' },
    { '<leader>no', function() require('neotest').output.open { enter = true } end, desc = '[N]eotest [O]utput' },
    { '<leader>np', function() require('neotest').output_panel.toggle() end, desc = '[N]eotest output [P]anel' },
    { '<leader>nd', function() require('neotest').run.run { strategy = 'dap' } end, desc = '[N]eotest [D]ebug nearest' },
    { '<leader>nx', function() require('neotest').run.stop() end, desc = '[N]eotest stop' },
  },
  config = function()
    require('neotest').setup {
      adapters = {
        require('neotest-golang') {
          dap_go_enabled = true,
        },
        -- Pest runs from the project's own vendor/bin/pest, so version drift
        -- between repos is a non-issue. Pest-style tests (the work repos) get
        -- per-test granularity; class-based PHPUnit files (meal-planner) still
        -- run through the pest binary, but only at file granularity.
        require 'neotest-pest',
      },
    }
  end,
}
