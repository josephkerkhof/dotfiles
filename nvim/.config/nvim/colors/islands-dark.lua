-- islands-dark.lua
-- A self-contained Neovim colorscheme matching JetBrains' Islands / New UI Dark.
-- Colors taken directly from the JetBrains New UI Dark editor + terminal palette,
-- so it lines up 1:1 with the matching Ghostty terminal config.
--
-- Install:  place this file at ~/.config/nvim/colors/islands-dark.lua
-- Use:      :colorscheme islands-dark   (or vim.cmd.colorscheme("islands-dark"))

vim.opt.background = 'dark'
vim.cmd 'highlight clear'
if vim.fn.exists 'syntax_on' == 1 then vim.cmd 'syntax reset' end
vim.g.colors_name = 'islands-dark'
vim.opt.termguicolors = true

local c = {
  -- surfaces
  bg = '#1E1F22', -- editor / terminal background
  bg_dark = '#131317', -- darker canvas (Islands panel gap); tweak to taste
  bg_panel = '#2B2D30', -- tool windows, statusline, tabs, floats
  bg_cursorln = '#26282E', -- caret row
  bg_hl = '#2B2D30', -- highlighted line
  sel = '#214283', -- selection
  border = '#393B40',
  border_alt = '#43454A',

  -- text
  fg = '#BCBEC4', -- default editor foreground
  fg_bright = '#DFE1E5',
  fg_muted = '#9DA0A8',
  fg_dim = '#6F737A',
  line_nr = '#4B5059',
  line_nr_act = '#A1A3AB',
  indent = '#313438',
  indent_act = '#666870',

  -- syntax (JetBrains New UI Dark)
  keyword = '#CF8E6D', -- keywords, booleans, builtins, escapes
  string = '#6AAB73',
  string_re = '#42C3D4',
  doc = '#5F826B', -- doc comments
  comment = '#7A7E85',
  number = '#2AACB8', -- numbers, floats
  func = '#56A8F5', -- functions, methods, constructors
  func_spec = '#FFC66D',
  member = '#C77DBB', -- fields, properties, constants, enums
  type = '#6FAFBD',
  attribute = '#D5B778', -- attributes, tags
  preproc = '#B3AE60',
  link = '#548AF7',
  accent = '#6B9BFA',

  -- ANSI / diagnostics
  red = '#F0524F',
  red_br = '#FF4050',
  green = '#5C962C',
  green_br = '#4FC414',
  yellow = '#A68A0D',
  yellow_br = '#E5BF00',
  blue = '#3993D4',
  blue_br = '#1FB0FF',
  magenta = '#A771BF',
  cyan = '#00A3A3',
  none = 'NONE',
}

local function hl(group, spec) vim.api.nvim_set_hl(0, group, spec) end

-- ── Editor UI ────────────────────────────────────────────────────────────
hl('Normal', { fg = c.fg, bg = c.bg })
hl('NormalNC', { fg = c.fg, bg = c.bg })
hl('NormalFloat', { fg = c.fg, bg = c.bg_panel })
hl('FloatBorder', { fg = c.border, bg = c.bg_panel })
hl('FloatTitle', { fg = c.fg_bright, bg = c.bg_panel, bold = true })
hl('Cursor', { fg = c.bg, bg = c.fg })
hl('CursorLine', { bg = c.bg_cursorln })
hl('CursorColumn', { bg = c.bg_cursorln })
hl('ColorColumn', { bg = c.bg_hl })
hl('LineNr', { fg = c.line_nr })
hl('CursorLineNr', { fg = c.line_nr_act, bold = true })
hl('SignColumn', { bg = c.bg })
hl('Folded', { fg = c.fg_muted, bg = c.bg_panel })
hl('FoldColumn', { fg = c.line_nr, bg = c.bg })
hl('WinSeparator', { fg = c.border })
hl('VertSplit', { fg = c.border })
hl('Visual', { bg = c.sel })
hl('VisualNOS', { bg = c.sel })
hl('Search', { bg = '#114957' })
hl('IncSearch', { bg = '#1A6B80' })
hl('CurSearch', { bg = '#1A6B80' })
hl('MatchParen', { fg = c.yellow_br, bold = true, underline = true })
hl('Whitespace', { fg = c.indent })
hl('NonText', { fg = c.fg_dim })
hl('SpecialKey', { fg = c.fg_dim })
hl('IndentBlanklineChar', { fg = c.indent })
hl('IndentBlanklineContextChar', { fg = c.indent_act })
hl('Directory', { fg = c.func })
hl('Title', { fg = c.member, bold = true })
hl('Conceal', { fg = c.fg_dim })
hl('WinBar', { fg = c.fg, bg = c.bg })
hl('WinBarNC', { fg = c.fg_muted, bg = c.bg })

-- popup menu / statusline / tabs
hl('Pmenu', { fg = c.fg, bg = c.bg_panel })
hl('PmenuSel', { fg = c.fg_bright, bg = c.sel })
hl('PmenuSbar', { bg = c.bg_panel })
hl('PmenuThumb', { bg = c.border_alt })
hl('StatusLine', { fg = c.fg, bg = c.bg_panel })
hl('StatusLineNC', { fg = c.fg_muted, bg = c.bg_panel })
hl('TabLine', { fg = c.fg_muted, bg = c.bg_panel })
hl('TabLineSel', { fg = c.fg_bright, bg = c.bg })
hl('TabLineFill', { bg = c.bg_panel })
hl('WildMenu', { fg = c.fg_bright, bg = c.sel })

-- messages
hl('ErrorMsg', { fg = c.red })
hl('WarningMsg', { fg = c.yellow_br })
hl('ModeMsg', { fg = c.fg })
hl('MoreMsg', { fg = c.green })
hl('Question', { fg = c.green })

-- ── Legacy syntax groups ─────────────────────────────────────────────────
hl('Comment', { fg = c.comment, italic = true })
hl('Constant', { fg = c.member })
hl('String', { fg = c.string })
hl('Character', { fg = c.string })
hl('Number', { fg = c.number })
hl('Float', { fg = c.number })
hl('Boolean', { fg = c.keyword })
hl('Identifier', { fg = c.fg })
hl('Function', { fg = c.func })
hl('Statement', { fg = c.keyword })
hl('Conditional', { fg = c.keyword })
hl('Repeat', { fg = c.keyword })
hl('Label', { fg = c.fg })
hl('Operator', { fg = c.fg })
hl('Keyword', { fg = c.keyword })
hl('Exception', { fg = c.keyword })
hl('PreProc', { fg = c.preproc })
hl('Include', { fg = c.keyword })
hl('Define', { fg = c.keyword })
hl('Macro', { fg = c.preproc })
hl('PreCondit', { fg = c.preproc })
hl('Type', { fg = c.type })
hl('StorageClass', { fg = c.keyword })
hl('Structure', { fg = c.type })
hl('Typedef', { fg = c.type })
hl('Special', { fg = c.keyword })
hl('SpecialChar', { fg = c.keyword })
hl('Tag', { fg = c.attribute })
hl('Delimiter', { fg = c.fg })
hl('SpecialComment', { fg = c.doc, italic = true })
hl('Debug', { fg = c.red })
hl('Underlined', { fg = c.link, underline = true })
hl('Todo', { fg = c.bg, bg = c.yellow_br, bold = true })
hl('Error', { fg = c.red })

-- ── Treesitter ───────────────────────────────────────────────────────────
hl('@comment', { link = 'Comment' })
hl('@comment.documentation', { fg = c.doc, italic = true })
hl('@comment.error', { fg = c.red })
hl('@comment.warning', { fg = c.yellow_br })
hl('@comment.todo', { link = 'Todo' })
hl('@comment.note', { fg = c.bg, bg = c.func, bold = true })

hl('@keyword', { fg = c.keyword })
hl('@keyword.function', { fg = c.keyword })
hl('@keyword.operator', { fg = c.keyword })
hl('@keyword.return', { fg = c.keyword })
hl('@keyword.import', { fg = c.keyword })
hl('@keyword.conditional', { fg = c.keyword })
hl('@keyword.repeat', { fg = c.keyword })
hl('@keyword.exception', { fg = c.keyword })

hl('@string', { fg = c.string })
hl('@string.regexp', { fg = c.string_re })
hl('@string.escape', { fg = c.keyword })
hl('@string.special', { fg = c.func })
hl('@character', { fg = c.string })
hl('@boolean', { fg = c.keyword })
hl('@number', { fg = c.number })
hl('@number.float', { fg = c.number })

hl('@function', { fg = c.func })
hl('@function.call', { fg = c.func })
hl('@function.method', { fg = c.func })
hl('@function.method.call', { fg = c.func })
hl('@function.builtin', { fg = c.func_spec })
hl('@constructor', { fg = c.func })

hl('@variable', { fg = c.fg })
hl('@variable.builtin', { fg = c.keyword })
hl('@variable.parameter', { fg = c.fg })
hl('@variable.member', { fg = c.member })

hl('@constant', { fg = c.member })
hl('@constant.builtin', { fg = c.keyword })
hl('@constant.macro', { fg = c.preproc })
hl('@property', { fg = c.member })
hl('@field', { fg = c.member })

hl('@type', { fg = c.type })
hl('@type.builtin', { fg = c.keyword })
hl('@type.definition', { fg = c.type })
hl('@attribute', { fg = c.attribute })
hl('@annotation', { fg = c.preproc })
hl('@namespace', { fg = c.type })
hl('@module', { fg = c.fg })

hl('@operator', { fg = c.fg })
hl('@punctuation.delimiter', { fg = c.fg })
hl('@punctuation.bracket', { fg = c.fg })
hl('@punctuation.special', { fg = c.keyword })

hl('@tag', { fg = c.attribute })
hl('@tag.attribute', { fg = c.member })
hl('@tag.delimiter', { fg = c.fg })

hl('@markup.heading', { fg = c.member, bold = true })
hl('@markup.strong', { fg = c.fg_bright, bold = true })
hl('@markup.italic', { fg = c.fg, italic = true })
hl('@markup.link', { fg = c.link, underline = true })
hl('@markup.link.url', { fg = c.link, underline = true })
hl('@markup.raw', { fg = c.string })
hl('@markup.list', { fg = c.keyword })

-- ── LSP semantic tokens ──────────────────────────────────────────────────
hl('@lsp.type.class', { fg = c.type })
hl('@lsp.type.enum', { fg = c.type })
hl('@lsp.type.interface', { fg = c.type })
hl('@lsp.type.struct', { fg = c.type })
hl('@lsp.type.namespace', { fg = c.type })
hl('@lsp.type.type', { fg = c.type })
hl('@lsp.type.function', { fg = c.func })
hl('@lsp.type.method', { fg = c.func })
hl('@lsp.type.property', { fg = c.member })
hl('@lsp.type.variable', { fg = c.fg })
hl('@lsp.type.parameter', { fg = c.fg })
hl('@lsp.type.enumMember', { fg = c.member })
hl('@lsp.type.keyword', { fg = c.keyword })
hl('@lsp.type.comment', { link = 'Comment' })
hl('@lsp.mod.readonly', { fg = c.member })

-- ── PHP-specific (matches JetBrains' PHP scheme, not the generic one) ────
-- JetBrains colors PHP $variables purple; the generic mapping above uses fg.
hl('@variable.php', { fg = c.member })
hl('@variable.parameter.php', { fg = c.member })
hl('@lsp.type.variable.php', { fg = c.member })
hl('@lsp.type.parameter.php', { fg = c.member })
-- Magic constants (__DIR__, __CLASS__, ...) are purple italic in JetBrains.
hl('@constant.builtin.php', { fg = c.member, italic = true })
hl('@lsp.typemod.constant.static.php', { fg = c.member, italic = true })

-- ── Inlay hints (JetBrains-style dim chip) ───────────────────────────────
hl('LspInlayHint', { fg = c.fg_dim, bg = c.bg_hl })

-- ── Document highlight (symbol under cursor; JetBrains' subtle tints) ────
hl('LspReferenceText', { bg = '#373B39' })
hl('LspReferenceRead', { bg = '#373B39' })
hl('LspReferenceWrite', { bg = '#402F33' })

-- ── Diagnostics ──────────────────────────────────────────────────────────
hl('DiagnosticError', { fg = c.red })
hl('DiagnosticWarn', { fg = c.yellow_br })
hl('DiagnosticInfo', { fg = c.blue_br })
hl('DiagnosticHint', { fg = c.fg_dim })
hl('DiagnosticOk', { fg = c.green })
hl('DiagnosticUnderlineError', { sp = c.red, undercurl = true })
hl('DiagnosticUnderlineWarn', { sp = c.yellow_br, undercurl = true })
hl('DiagnosticUnderlineInfo', { sp = c.blue_br, undercurl = true })
hl('DiagnosticUnderlineHint', { sp = c.fg_dim, undercurl = true })

-- ── Git / diff ───────────────────────────────────────────────────────────
hl('DiffAdd', { bg = '#294436' })
hl('DiffChange', { bg = '#303C47' })
hl('DiffDelete', { bg = '#484A4A' })
hl('DiffText', { bg = '#3A5364' })
hl('Added', { fg = c.green })
hl('Changed', { fg = c.blue })
hl('Removed', { fg = c.red })
hl('GitSignsAdd', { fg = c.green })
hl('GitSignsChange', { fg = c.blue })
hl('GitSignsDelete', { fg = c.red })

-- ── A few common plugins (Telescope, which-key, cmp) ─────────────────────
hl('TelescopeNormal', { fg = c.fg, bg = c.bg_panel })
hl('TelescopeBorder', { fg = c.border, bg = c.bg_panel })
hl('TelescopeSelection', { fg = c.fg_bright, bg = c.sel })
hl('TelescopeMatching', { fg = c.func_spec, bold = true })
hl('TelescopePromptTitle', { fg = c.bg, bg = c.member, bold = true })
hl('CmpItemAbbrMatch', { fg = c.func, bold = true })
hl('CmpItemKind', { fg = c.member })
hl('WhichKey', { fg = c.func })
hl('WhichKeyGroup', { fg = c.member })
hl('WhichKeyDesc', { fg = c.fg })

-- ── Terminal colors (matches the Ghostty palette) ────────────────────────
vim.g.terminal_color_0 = '#000000'
vim.g.terminal_color_1 = '#F0524F'
vim.g.terminal_color_2 = '#5C962C'
vim.g.terminal_color_3 = '#A68A0D'
vim.g.terminal_color_4 = '#3993D4'
vim.g.terminal_color_5 = '#A771BF'
vim.g.terminal_color_6 = '#00A3A3'
vim.g.terminal_color_7 = '#808080'
vim.g.terminal_color_8 = '#595959'
vim.g.terminal_color_9 = '#FF4050'
vim.g.terminal_color_10 = '#4FC414'
vim.g.terminal_color_11 = '#E5BF00'
vim.g.terminal_color_12 = '#1FB0FF'
vim.g.terminal_color_13 = '#ED7EED'
vim.g.terminal_color_14 = '#00E5E5'
vim.g.terminal_color_15 = '#FFFFFF'
