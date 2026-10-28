-- hopparch nvim: the 0xyc look. The editor itself (background, text, lines,
-- menus) uses the same colours as the rest of the desktop (kitty, waybar,
-- fuzzel, mako, hyprland, hyprlock). Code gets six muted tones on top, all
-- about as bright as each other so none of them shouts:
--
--   amber + bold     language keywords           the skeleton of the code
--   sage             functions                   things that run
--   slate            types                       the shape of data
--   rose             strings                     text
--   violet           numbers, constants, true    fixed values
--   teal + italic    #include, #define, macros   the preprocessor
--   cream            identifiers, operators      ordinary code
--   grey + italic    comments                    prose
--   red              errors                      failure only, as on the lock screen
local c = {
  black = "#000000", -- every background
  dim   = "#2a2a28", -- cursor line, folds (kitty's selection colour)
  grey  = "#3a3a38", -- borders, separators, visual selection
  mid   = "#8a877f", -- comments, line numbers
  cream = "#e8e4dc", -- normal text
  white = "#ffffff", -- emphasis and matches (fuzzel uses it for the match)
  red   = "#c23d3d", -- failure only (hyprlock's fail_color)
  -- code tones
  amber  = "#d7a96b",
  sage   = "#a9c29b",
  slate  = "#8fb0c8",
  rose   = "#cf9f93",
  violet = "#b3a3d6",
  teal   = "#8ec3b9",
}

vim.cmd.highlight("clear")
vim.g.colors_name = "0xyc"
vim.o.background = "dark"

local hl = {
  -- editor
  Normal       = { fg = c.cream, bg = c.black },
  NormalFloat  = { fg = c.cream, bg = c.black },
  FloatBorder  = { fg = c.grey,  bg = c.black },
  FloatTitle   = { fg = c.white, bold = true },
  Cursor       = { fg = c.black, bg = c.cream },
  TermCursor   = { fg = c.black, bg = c.cream },
  CursorLine   = { bg = c.dim },
  CursorLineNr = { fg = c.cream, bold = true },
  LineNr       = { fg = c.grey },
  SignColumn   = { bg = c.black },
  ColorColumn  = { bg = c.dim },
  Visual       = { bg = c.grey },
  VisualNOS    = { bg = c.grey },
  Search       = { fg = c.black, bg = c.mid },
  IncSearch    = { fg = c.black, bg = c.white },
  CurSearch    = { fg = c.black, bg = c.white },
  MatchParen   = { fg = c.white, bold = true, underline = true },
  Folded       = { fg = c.mid,   bg = c.dim },
  FoldColumn   = { fg = c.grey },
  NonText      = { fg = c.grey },
  Whitespace   = { fg = c.grey },
  SpecialKey   = { fg = c.grey },
  EndOfBuffer  = { fg = c.black }, -- no column of ~ under the last line
  Conceal      = { fg = c.grey },
  Directory    = { fg = c.cream, bold = true },
  Title        = { fg = c.white, bold = true },
  WinSeparator = { fg = c.grey },
  QuickFixLine = { bg = c.grey },

  -- status, tabs, the completion menu
  StatusLine   = { fg = c.cream, bg = c.dim },
  StatusLineNC = { fg = c.mid,   bg = c.black },
  TabLine      = { fg = c.mid,   bg = c.dim },
  TabLineSel   = { fg = c.cream, bg = c.black, bold = true },
  TabLineFill  = { bg = c.black },
  Pmenu        = { fg = c.cream, bg = c.dim },
  PmenuSel     = { fg = c.cream, bg = c.grey, bold = true },
  PmenuKind    = { fg = c.mid,   bg = c.dim },
  PmenuExtra   = { fg = c.mid,   bg = c.dim },
  PmenuSbar    = { bg = c.dim },
  PmenuThumb   = { bg = c.grey },
  WildMenu     = { fg = c.black, bg = c.cream },

  -- messages
  ModeMsg      = { fg = c.cream, bold = true },
  MoreMsg      = { fg = c.cream },
  Question     = { fg = c.cream },
  WarningMsg   = { fg = c.white, bold = true },
  ErrorMsg     = { fg = c.red,   bold = true },

  -- syntax: the code tones (top of the file)
  Comment      = { fg = c.mid,    italic = true },
  Keyword      = { fg = c.amber,  bold = true },
  Statement    = { fg = c.amber,  bold = true },
  Conditional  = { fg = c.amber,  bold = true },
  Repeat       = { fg = c.amber,  bold = true },
  Label        = { fg = c.amber,  bold = true },
  Exception    = { fg = c.amber,  bold = true },
  Operator     = { fg = c.cream },
  Function     = { fg = c.sage },
  Type         = { fg = c.slate },
  Structure    = { fg = c.slate },
  StorageClass = { fg = c.amber,  bold = true },
  Typedef      = { fg = c.slate },
  Identifier   = { fg = c.cream },
  Constant     = { fg = c.violet },
  String       = { fg = c.rose },
  Character    = { fg = c.rose },
  Number       = { fg = c.violet },
  Float        = { fg = c.violet },
  Boolean      = { fg = c.violet },
  PreProc      = { fg = c.teal,   italic = true },
  Include      = { fg = c.teal,   italic = true },
  Define       = { fg = c.teal,   italic = true },
  Macro        = { fg = c.teal,   italic = true },
  Special      = { fg = c.cream },
  SpecialChar  = { fg = c.white },
  Delimiter    = { fg = c.cream },
  Tag          = { fg = c.cream },
  Underlined   = { fg = c.cream, underline = true },
  Ignore       = { fg = c.grey },
  Todo         = { fg = c.black, bg = c.white, bold = true },
  Error        = { fg = c.red },

  -- diffs: added/changed by background, removed in the one warm colour
  DiffAdd      = { fg = c.cream, bg = c.dim },
  DiffChange   = { fg = c.mid,   bg = c.black },
  DiffText     = { fg = c.white, bg = c.grey, bold = true },
  DiffDelete   = { fg = c.red,   bg = c.black },

  -- diagnostics: error red, warning amber, info slate, hint grey
  DiagnosticError = { fg = c.red },
  DiagnosticWarn  = { fg = c.amber },
  DiagnosticInfo  = { fg = c.slate },
  DiagnosticHint  = { fg = c.mid },
  DiagnosticOk    = { fg = c.sage },
  DiagnosticUnderlineError = { undercurl = true, sp = c.red },
  DiagnosticUnderlineWarn  = { undercurl = true, sp = c.amber },
  DiagnosticUnderlineInfo  = { undercurl = true, sp = c.slate },
  DiagnosticUnderlineHint  = { undercurl = true, sp = c.mid },
  DiagnosticVirtualTextError = { fg = c.red,   bg = c.black, italic = true },
  DiagnosticVirtualTextWarn  = { fg = c.mid,   bg = c.black, italic = true },
  DiagnosticVirtualTextInfo  = { fg = c.mid,   bg = c.black, italic = true },
  DiagnosticVirtualTextHint  = { fg = c.grey,  bg = c.black, italic = true },

  -- LSP
  LspReferenceText  = { bg = c.grey },
  LspReferenceRead  = { bg = c.grey },
  LspReferenceWrite = { bg = c.grey, bold = true },
  LspSignatureActiveParameter = { fg = c.white, bold = true },
  LspInlayHint      = { fg = c.grey, italic = true },

  -- treesitter: the groups nvim does not already link to the ones above
  ["@variable"]         = { fg = c.cream },
  ["@variable.builtin"] = { fg = c.cream, italic = true },
  ["@function.builtin"] = { fg = c.sage,  italic = true },
  ["@type.builtin"]     = { fg = c.slate, italic = true },
  ["@constant.builtin"] = { fg = c.violet },
  ["@module"]           = { fg = c.cream },
  ["@attribute"]        = { fg = c.teal,  italic = true },
  ["@property"]         = { fg = c.cream },
  ["@field"]            = { fg = c.cream },
  ["@punctuation"]      = { fg = c.cream },
  ["@comment.todo"]     = { link = "Todo" },
  ["@comment.note"]     = { fg = c.cream, italic = true },
  ["@comment.warning"]  = { fg = c.white, italic = true },
  ["@comment.error"]    = { fg = c.red,   italic = true },
  ["@markup.heading"]   = { fg = c.white, bold = true },
  ["@markup.strong"]    = { bold = true },
  ["@markup.italic"]    = { italic = true },
  ["@markup.strikethrough"] = { strikethrough = true },
  ["@markup.link"]      = { fg = c.cream, underline = true },
  ["@markup.link.url"]  = { fg = c.mid,   underline = true },
  ["@markup.raw"]       = { fg = c.mid },
  ["@markup.list"]      = { fg = c.cream },
  ["@diff.plus"]        = { link = "DiffAdd" },
  ["@diff.minus"]       = { link = "DiffDelete" },
  ["@diff.delta"]       = { link = "DiffChange" },

  -- netrw (Space e)
  netrwDir     = { fg = c.cream, bold = true },
  netrwClassify = { fg = c.grey },
  netrwExe     = { fg = c.white },
  netrwSymLink = { fg = c.mid,   italic = true },
}

for group, spec in pairs(hl) do
  vim.api.nvim_set_hl(0, group, spec)
end

-- The terminal that Space r / Space g opens shows compiler output in the same
-- tones: red errors, amber (yellow) warnings, slate (blue) and teal (cyan) notes.
--            black    red    green   yellow   blue     magenta   cyan    white
local ansi = {
  c.black, c.red, c.sage, c.amber, c.slate, c.violet, c.teal, c.cream,
  c.grey,  c.red, c.sage, c.amber, c.slate, c.violet, c.teal, c.white,
}
for i, colour in ipairs(ansi) do
  vim.g["terminal_color_" .. (i - 1)] = colour
end
