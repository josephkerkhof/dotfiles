-- render-markdown: in-buffer markdown rendering via extmarks/conceal on top
-- of the treesitter markdown parsers already installed. Modal by default --
-- insert mode drops back to raw text, so the toggle is only for viewing the
-- whole file as source.
---@module 'lazy'
---@type LazySpec
return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },
  ft = 'markdown',
  opts = {
    -- All-or-none rendering: keep marks in every mode (insert included) and on the
    -- cursor line. Raw source is only ever a <leader>tm away.
    render_modes = true,
    anti_conceal = { enabled = false },
    -- Default icons are nerd-font circled digits; keep the colored band, show raw '#'s.
    heading = { sign = false, icons = {} },
    -- 'padded' inflates every cell to the column max; only render actual content width.
    pipe_table = { cell = 'trimmed' },
  },
  keys = {
    { '<leader>tm', '<cmd>RenderMarkdown buf_toggle<cr>', desc = '[T]oggle [M]arkdown render' },
  },
}
