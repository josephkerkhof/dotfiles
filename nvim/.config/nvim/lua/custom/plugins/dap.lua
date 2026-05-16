---@module 'lazy'
---@type LazySpec
return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'nvim-neotest/nvim-nio',
    { 'rcarriga/nvim-dap-ui', opts = {} },
    { 'theHamsta/nvim-dap-virtual-text', opts = {} },
    { 'leoluz/nvim-dap-go', opts = {} },
  },
  keys = {
    { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = '[D]ebug [B]reakpoint' },
    { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input 'Condition: ') end, desc = '[D]ebug Conditional [B]reakpoint' },
    { '<leader>dc', function() require('dap').continue() end, desc = '[D]ebug [C]ontinue' },
    { '<leader>di', function() require('dap').step_into() end, desc = '[D]ebug step [I]nto' },
    { '<leader>do', function() require('dap').step_over() end, desc = '[D]ebug step [O]ver' },
    { '<leader>dO', function() require('dap').step_out() end, desc = '[D]ebug step [O]ut' },
    { '<leader>dr', function() require('dap').repl.open() end, desc = '[D]ebug [R]epl' },
    { '<leader>dl', function() require('dap').run_last() end, desc = '[D]ebug run [L]ast' },
    { '<leader>du', function() require('dapui').toggle() end, desc = '[D]ebug [U]I toggle' },
    { '<leader>dt', function() require('dap-go').debug_test() end, desc = '[D]ebug nearest go [T]est' },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
    dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
    dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end
  end,
}
