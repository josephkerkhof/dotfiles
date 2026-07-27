---@module 'lazy'
---@type LazySpec
return {
  'NickvanDyke/opencode.nvim',
  version = '*',
  dependencies = { 'akinsho/toggleterm.nvim' },
  lazy = false,
  config = function()
    local Terminal = require('toggleterm.terminal').Terminal
    local terminal = Terminal:new {
      cmd = 'opencode --port',
      direction = 'vertical',
      display_name = 'OpenCode',
      hidden = true,
    }

    require('opencode.config').opts.server.start = function()
      terminal:open(math.max(50, math.floor(vim.o.columns * 0.4)))
      vim.schedule(function()
        if terminal:is_focused() then
          vim.cmd.stopinsert()
          vim.cmd.wincmd 'p'
        end
      end)
    end

    vim.keymap.set({ 'n', 'x' }, '<leader>aa', function() require('opencode').ask '@this: ' end, { desc = '[A]sk OpenCode' })
    vim.keymap.set('n', '<leader>as', function() require('opencode').select() end, { desc = '[S]elect OpenCode action' })
    vim.keymap.set('n', '<leader>at', function() terminal:toggle(math.max(50, math.floor(vim.o.columns * 0.4))) end, { desc = '[T]oggle OpenCode' })
    vim.keymap.set(
      { 'n', 'x' },
      '<leader>ar',
      function() require('opencode').prompt 'Review @this for correctness and readability' end,
      { desc = '[R]eview with OpenCode' }
    )
    vim.keymap.set({ 'n', 'x' }, '<leader>af', function() require('opencode').prompt 'Fix @diagnostics' end, { desc = '[F]ix diagnostics with OpenCode' })
    vim.keymap.set('n', '<leader>an', function() require('opencode').command 'session.new' end, { desc = '[N]ew OpenCode session' })
  end,
}
