-- Personal Neovim config.
-- Started from kickstart.nvim, then cut down toward the tools I actually use.

if vim.g.nix_nvim_config then
  -- The wrapped config is authoritative even while the old Stow link exists.
  local stow_config = vim.fn.stdpath 'config'
  vim.opt.runtimepath:remove(stow_config)
  vim.opt.runtimepath:remove(stow_config .. '/after')
  local mutable_site = vim.fn.stdpath 'data' .. '/site'
  vim.opt.runtimepath:remove(mutable_site)
  vim.opt.runtimepath:remove(mutable_site .. '/after')
else
  -- Keep the Stow-managed editor usable until the coordinated Nix cutover.
  local excluded = {
    ['lazy.nvim'] = true,
    ['lazydev.nvim'] = true,
    ['mason-lspconfig.nvim'] = true,
    ['mason-tool-installer.nvim'] = true,
    ['mason.nvim'] = true,
  }
  for _, plugin in ipairs(vim.fn.glob(vim.fn.stdpath 'data' .. '/lazy/*', false, true)) do
    if not excluded[vim.fs.basename(plugin)] then vim.opt.runtimepath:append(plugin) end
  end
  vim.g.nix_nvim_config = vim.fn.stdpath 'config'
  vim.g.js_debug_adapter = 'js-debug-adapter'
  vim.g.vue_typescript_plugin_path = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'
end

-- Set <space> as the leader key before plugins are configured.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
vim.o.breakindent = true
vim.o.undofile = true
vim.o.sessionoptions = 'blank,buffers,curdir,folds,help,localoptions,tabpages,winsize,terminal'
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.colorcolumn = '120'
vim.o.scrolloff = 10
vim.o.confirm = true
vim.o.foldlevel = 99

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = true,
  virtual_lines = false,
  jump = {
    on_jump = function(diagnostic, bufnr)
      if diagnostic then vim.diagnostic.open_float { bufnr = bufnr } end
    end,
  },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

local function copy_file_path(modifiers)
  return function()
    local path = vim.fn.expand('%' .. modifiers)
    vim.fn.setreg('+', path)
    vim.notify('Copied: ' .. path)
  end
end
vim.keymap.set('n', '<leader>cfp', copy_file_path ':.', { desc = '[C]opy [F]ile [P]ath' })
vim.keymap.set('n', '<leader>cfa', copy_file_path ':p', { desc = '[C]opy [F]ile [A]bsolute path' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Enable spell checking for prose filetypes',
  pattern = { 'markdown', 'text', 'gitcommit' },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { 'en' }
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Disable soft wrap for markdown -- pipe tables shear when a row wraps',
  pattern = 'markdown',
  callback = function() vim.opt_local.wrap = false end,
})

vim.filetype.add {
  pattern = {
    ['.*%.blade%.php'] = 'blade',
  },
}

require('guess-indent').setup {}

require('which-key').setup {
  delay = 0,
  icons = { mappings = vim.g.have_nerd_font },
  spec = {
    { '<leader>a', group = '[A]gent', mode = { 'n', 'v' } },
    { '<leader>c', group = '[C]opy' },
    { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
    { '<leader>d', group = '[D]ebug' },
    { '<leader>n', group = '[N]eotest' },
    { '<leader>T', group = '[T]est' },
    { 'gr', group = 'LSP Actions', mode = { 'n' } },
  },
}

require('telescope').setup {
  defaults = {
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
      '--hidden',
      '--glob=!.git/',
    },
  },
  pickers = {
    find_files = {
      find_command = { 'rg', '--files', '--hidden', '--glob=!.git/', '--color=never' },
    },
  },
  extensions = {
    ['ui-select'] = { require('telescope.themes').get_dropdown() },
  },
}

pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')

local telescope = require 'telescope.builtin'
vim.keymap.set('n', '<leader>sh', telescope.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', telescope.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', telescope.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', telescope.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set({ 'n', 'v' }, '<leader>sw', telescope.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', telescope.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', telescope.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', telescope.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', telescope.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader>sc', telescope.commands, { desc = '[S]earch [C]ommands' })
vim.keymap.set('n', '<leader><leader>', telescope.buffers, { desc = '[ ] Find existing buffers' })

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf
    vim.keymap.set('n', 'grr', telescope.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
    vim.keymap.set('n', 'gri', telescope.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
    vim.keymap.set('n', 'grd', telescope.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
    vim.keymap.set('n', 'gO', telescope.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
    vim.keymap.set('n', 'gW', telescope.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
    vim.keymap.set('n', 'grt', telescope.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
  end,
})

vim.keymap.set(
  'n',
  '<leader>/',
  function()
    telescope.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      winblend = 10,
      previewer = false,
    })
  end,
  { desc = '[/] Fuzzily search in current buffer' }
)

vim.keymap.set(
  'n',
  '<leader>s/',
  function()
    telescope.live_grep {
      grep_open_files = true,
      prompt_title = 'Live Grep in Open Files',
    }
  end,
  { desc = '[S]earch [/] in Open Files' }
)

vim.keymap.set('n', '<leader>sn', function() telescope.find_files { cwd = vim.g.nix_nvim_config } end, { desc = '[S]earch [N]eovim files' })

require('fidget').setup {}
require('luasnip').setup {}

local blink = require 'blink.cmp'
blink.setup {
  keymap = { preset = 'default' },
  appearance = { nerd_font_variant = 'mono' },
  completion = {
    documentation = { auto_show = false, auto_show_delay_ms = 500 },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets' },
  },
  snippets = { preset = 'luasnip' },
  fuzzy = { implementation = 'lua' },
  signature = { enabled = true },
}
local capabilities = blink.get_lsp_capabilities()

-- IntelliJ-style gutter indicators from LSP code lenses. PHPantom puts an
-- "↑ Parent::method" / "◆ Interface::method" lens on overriding methods;
-- the lens title's leading symbol becomes a sign and `grs` runs that lens.
local lens_group = vim.api.nvim_create_augroup('kickstart-codelens', { clear = true })
local lens_ns = vim.api.nvim_create_namespace 'codelens-gutter'
local lens_state = {} ---@type table<integer, table<integer, { client_id: integer, command: lsp.Command }>>
local lens_tick = {}

local function lens_refresh(bufnr)
  local clients = vim.lsp.get_clients { bufnr = bufnr, method = 'textDocument/codeLens' }
  if #clients == 0 then return end
  local remaining, collected = #clients, {}
  for _, client in ipairs(clients) do
    local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
    client:request('textDocument/codeLens', params, function(err, result)
      for _, lens in ipairs((not err and result) or {}) do
        if lens.command then table.insert(collected, { client_id = client.id, lens = lens }) end
      end
      remaining = remaining - 1
      if remaining > 0 or not vim.api.nvim_buf_is_valid(bufnr) then return end
      vim.api.nvim_buf_clear_namespace(bufnr, lens_ns, 0, -1)
      local by_extmark = {}
      for _, item in ipairs(collected) do
        local sign = vim.fn.strcharpart(item.lens.command.title, 0, 1)
        if sign:match '^%w' then sign = '•' end
        local ok, id = pcall(vim.api.nvim_buf_set_extmark, bufnr, lens_ns, item.lens.range.start.line, 0, {
          sign_text = sign,
          sign_hl_group = 'LspCodeLens',
        })
        if ok then by_extmark[id] = { client_id = item.client_id, command = item.lens.command } end
      end
      lens_state[bufnr] = by_extmark
    end, bufnr)
  end
end

local function lens_run()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local mark = vim.api.nvim_buf_get_extmarks(bufnr, lens_ns, { row, 0 }, { row, -1 }, {})[1]
  local lens = mark and (lens_state[bufnr] or {})[mark[1]]
  if not lens then return vim.notify('No code lens on this line', vim.log.levels.INFO) end
  local client = vim.lsp.get_client_by_id(lens.client_id)
  if client then client:exec_cmd(lens.command, { bufnr = bufnr }) end
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
      map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
    end

    if client and client:supports_method('textDocument/codeLens', event.buf) then
      lens_state[event.buf] = lens_state[event.buf] or {}
      lens_refresh(event.buf)
      map('grs', lens_run, '[G]oto [S]uper')
    end
  end,
})

-- Re-request lenses whenever a server finishes background work.
vim.api.nvim_create_autocmd('LspProgress', {
  group = lens_group,
  pattern = 'end',
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then return end
    for bufnr in pairs(client.attached_buffers) do
      if lens_state[bufnr] then lens_refresh(bufnr) end
    end
  end,
})

-- Debounced re-request after edits; extmarks keep existing signs on their lines.
vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
  group = lens_group,
  callback = function(event)
    if not lens_state[event.buf] then return end
    local tick = (lens_tick[event.buf] or 0) + 1
    lens_tick[event.buf] = tick
    vim.defer_fn(function()
      if lens_tick[event.buf] == tick and vim.api.nvim_buf_is_valid(event.buf) then lens_refresh(event.buf) end
    end, 300)
  end,
})

vim.api.nvim_create_autocmd('LspDetach', {
  group = lens_group,
  callback = function(event)
    local others = vim.tbl_filter(
      function(client) return client.id ~= event.data.client_id end,
      vim.lsp.get_clients { bufnr = event.buf, method = 'textDocument/codeLens' }
    )
    if #others == 0 and lens_state[event.buf] then
      lens_state[event.buf], lens_tick[event.buf] = nil, nil
      if vim.api.nvim_buf_is_valid(event.buf) then vim.api.nvim_buf_clear_namespace(event.buf, lens_ns, 0, -1) end
    end
  end,
})

-- PHPantom sends this client-side command for override lenses.
vim.lsp.commands['editor.action.showReferences'] = function(command, ctx)
  local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
  local locations = command.arguments[3]
  if #locations == 1 then
    vim.lsp.util.show_document(locations[1], client.offset_encoding, { focus = true })
  else
    vim.fn.setqflist({}, ' ', {
      title = command.title,
      items = vim.lsp.util.locations_to_items(locations, client.offset_encoding),
    })
    vim.cmd.copen()
  end
end

---@type table<string, vim.lsp.Config>
local servers = {
  gopls = {
    settings = {
      gopls = {
        usePlaceholders = true,
        completeUnimported = true,
        staticcheck = true,
        semanticTokens = true,
        codelenses = {
          generate = true,
          gc_details = true,
          test = true,
          tidy = true,
          upgrade_dependency = true,
          vendor = true,
        },
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
        analyses = {
          nilness = true,
          shadow = true,
          unusedparams = true,
          unusedwrite = true,
          useany = true,
        },
      },
    },
  },
  pyright = {},
  yamlls = {},
  vtsls = {
    filetypes = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'vue' },
    settings = {
      vtsls = {
        tsserver = {
          globalPlugins = {
            {
              name = '@vue/typescript-plugin',
              location = vim.g.vue_typescript_plugin_path,
              languages = { 'vue' },
              configNamespace = 'typescript',
            },
          },
        },
      },
    },
  },
  vue_ls = {},
  lua_ls = {
    on_init = function(client)
      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end

      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkThirdParty = false,
          library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          }),
        },
      })
    end,
    settings = {
      Lua = {},
    },
  },
}

for name, server in pairs(servers) do
  server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end

vim.lsp.config('phpantom', {
  cmd = { 'phpantom_lsp' },
  filetypes = { 'php' },
  root_markers = { 'composer.json', '.git' },
  capabilities = vim.deepcopy(capabilities),
})
vim.lsp.enable 'phpantom'

require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    local disable_filetypes = { c = true, cpp = true }
    if disable_filetypes[vim.bo[bufnr].filetype] then return nil end
    return {
      timeout_ms = 500,
      lsp_format = 'fallback',
    }
  end,
  formatters_by_ft = {
    go = { 'goimports' },
    html = { 'prettier' },
    json = { 'prettier' },
    lua = { 'stylua' },
    php = { 'pint' },
    python = { 'ruff_organize_imports', 'ruff_format' },
    yaml = { 'prettier' },
  },
}

vim.keymap.set('', '<leader>f', function() require('conform').format { async = true, lsp_format = 'fallback' } end, { desc = '[F]ormat buffer' })

require('tokyonight').setup {
  styles = {
    comments = { italic = true },
  },
}
vim.cmd.colorscheme 'islands-dark'

require('todo-comments').setup { signs = false }
require('mini.ai').setup { n_lines = 500 }
require('mini.surround').setup()
local statusline = require 'mini.statusline'
statusline.setup { use_icons = vim.g.have_nerd_font }
statusline.section_location = function() return '%2l:%-2v' end

local parser_path = vim.api.nvim_get_runtime_file('parser/bash.so', false)[1]
assert(parser_path, 'packaged Treesitter parsers are missing')
require('nvim-treesitter').setup {
  install_dir = vim.fn.fnamemodify(parser_path, ':h:h'),
}

-- Only activate parsers shipped in the immutable plugin closure.
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local language = vim.treesitter.language.get_lang(args.match)
    if not language or not vim.treesitter.language.add(language) then return end
    vim.treesitter.start(args.buf, language)
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.wo.foldmethod = 'expr'
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- Dependency-sensitive order: ToggleTerm before its consumers, DAP before Neotest.
require 'custom.plugins'
require 'custom.plugins.autopairs'
require 'custom.plugins.dap'
require 'custom.plugins.gitsigns'
require 'custom.plugins.neo-tree'
require 'custom.plugins.neotest'
require 'custom.plugins.opencode'
require 'custom.plugins.render-markdown'
require 'custom.plugins.vim-test'

-- vim: ts=2 sts=2 sw=2 et
