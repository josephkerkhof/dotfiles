local dap = require 'dap'
local dapui = require 'dapui'

dapui.setup {}
require('nvim-dap-virtual-text').setup {}
require('dap-go').setup {}

vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = '[D]ebug [B]reakpoint' })
vim.keymap.set('n', '<leader>dB', function() dap.set_breakpoint(vim.fn.input 'Condition: ') end, { desc = '[D]ebug Conditional [B]reakpoint' })
vim.keymap.set('n', '<leader>dc', dap.continue, { desc = '[D]ebug [C]ontinue' })
vim.keymap.set('n', '<leader>di', dap.step_into, { desc = '[D]ebug step [I]nto' })
vim.keymap.set('n', '<leader>do', dap.step_over, { desc = '[D]ebug step [O]ver' })
vim.keymap.set('n', '<leader>dO', dap.step_out, { desc = '[D]ebug step [O]ut' })
vim.keymap.set('n', '<leader>dr', dap.repl.open, { desc = '[D]ebug [R]epl' })
vim.keymap.set('n', '<leader>dl', dap.run_last, { desc = '[D]ebug run [L]ast' })
vim.keymap.set('n', '<leader>du', dapui.toggle, { desc = '[D]ebug [U]I toggle' })
vim.keymap.set('n', '<leader>dt', function() require('dap-go').debug_test() end, { desc = '[D]ebug nearest go [T]est' })

dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end

dap.adapters['pwa-node'] = {
  type = 'server',
  host = 'localhost',
  port = '${port}',
  executable = {
    command = vim.g.js_debug_adapter,
    args = { '${port}' },
  },
}

dap.configurations.typescript = {
  {
    type = 'pwa-node',
    request = 'launch',
    name = 'Launch current file',
    program = '${file}',
    cwd = '${workspaceFolder}',
    sourceMaps = true,
    console = 'integratedTerminal',
    skipFiles = { '<node_internals>/**', '**/node_modules/**' },
  },
  {
    type = 'pwa-node',
    request = 'attach',
    name = 'Attach to port 9229',
    port = 9229,
    cwd = '${workspaceFolder}',
    sourceMaps = true,
    skipFiles = { '<node_internals>/**', '**/node_modules/**' },
  },
}
dap.configurations.typescriptreact = dap.configurations.typescript

dap.adapters.php = {
  type = 'executable',
  command = 'php-debug-adapter',
}

-- Neovim listens; Xdebug connects to it on 9003. Start with <leader>dc,
-- then trigger a request/test with Xdebug enabled.
dap.configurations.php = {
  {
    type = 'php',
    request = 'launch',
    name = 'Listen for Xdebug',
    port = 9003,
    -- Native project runtimes use matching paths. For containers, add
    -- pathMappings = { ['/var/www/html'] = '${workspaceFolder}' }.
  },
}
