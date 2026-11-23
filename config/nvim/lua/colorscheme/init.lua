-- Glyph Nothing OS Colorscheme
-- Black (#000000), White (#F2F2F2), Crimson (#D71921), Gray ramps

local M = {}

M.setup = function()
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end
  vim.o.termguicolors = true
  vim.g.colors_name = "glyph-nothing"

  -- Palette
  local c = {
    -- Base
    bg = "#000000",        -- Pure black
    bg_alt = "#0E0E0E",    -- Slightly elevated
    bg_high = "#1A1A1A",   -- Cards, popovers
    fg = "#F2F2F2",        -- Near white
    fg_dim = "#8C8C8C",    -- Muted
    fg_mute = "#4A4A4A",   -- Very muted

    -- Accent
    accent = "#D71921",    -- Crimson
    accent_dim = "#B0141B",
    accent_light = "#E83A3A",

    -- Grays
    gray0 = "#2A2A2A",     -- Borders
    gray1 = "#4A4A4A",     -- Inactive
    gray2 = "#8C8C8C",     -- Comments
    gray3 = "#C0C0C0",     -- Less muted

    -- Syntax
    red = "#D71921",
    orange = "#E87D1E",
    yellow = "#F2C84B",
    green = "#4EC9B0",
    cyan = "#9CDCFE",
    blue = "#569CD6",
    purple = "#C586C0",
    pink = "#D16969",

    -- Diff
    diff_add = "#1A3A2A",
    diff_delete = "#3A1A1A",
    diff_change = "#1A2A3A",
    diff_text = "#2A3A4A",

    -- Git
    git_add = "#4EC9B0",
    git_change = "#569CD6",
    git_delete = "#D71921",

    -- Diagnostic
    error = "#D71921",
    warn = "#E87D1E",
    info = "#569CD6",
    hint = "#4EC9B0",
  }

  local function hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- Editor highlights
  hl("Normal", { fg = c.fg, bg = c.bg })
  hl("NormalNC", { fg = c.fg, bg = c.bg })
  hl("NormalFloat", { fg = c.fg, bg = c.bg_alt })
  hl("FloatBorder", { fg = c.gray0, bg = c.bg_alt })
  hl("FloatTitle", { fg = c.accent, bg = c.bg_alt, bold = true })
  hl("FloatFooter", { fg = c.fg_dim, bg = c.bg_alt })

  hl("CursorLine", { bg = c.bg_alt })
  hl("CursorLineNr", { fg = c.accent, bold = true })
  hl("LineNr", { fg = c.gray1 })
  hl("LineNrAbove", { fg = c.gray1 })
  hl("LineNrBelow", { fg = c.gray1 })

  hl("SignColumn", { bg = c.bg })
  hl("FoldColumn", { bg = c.bg, fg = c.gray1 })
  hl("ColorColumn", { bg = c.bg_alt })

  hl("Visual", { bg = "#3A3A3A" })
  hl("VisualNOS", { bg = "#3A3A3A" })
  hl("Search", { fg = c.bg, bg = c.yellow })
  hl("IncSearch", { fg = c.bg, bg = c.accent })
  hl("CurSearch", { fg = c.bg, bg = c.accent })
  hl("MatchParen", { fg = c.accent, bg = c.bg_high, bold = true, underline = true })

  hl("Directory", { fg = c.blue })
  hl("Title", { fg = c.fg, bold = true })
  hl("NonText", { fg = c.gray1 })
  hl("SpecialKey", { fg = c.gray1 })
  hl("Whitespace", { fg = c.gray0 })
  hl("EndOfBuffer", { fg = c.bg })

  hl("Pmenu", { fg = c.fg, bg = c.bg_alt })
  hl("PmenuSel", { fg = c.bg, bg = c.fg })
  hl("PmenuSbar", { bg = c.gray0 })
  hl("PmenuThumb", { bg = c.gray2 })
  hl("PmenuKind", { fg = c.cyan })
  hl("PmenuKindSel", { fg = c.bg, bg = c.fg })
  hl("PmenuExtra", { fg = c.gray2 })
  hl("PmenuExtraSel", { fg = c.bg, bg = c.fg })

  hl("StatusLine", { fg = c.fg, bg = c.bg_alt })
  hl("StatusLineNC", { fg = c.gray2, bg = c.bg })
  hl("TabLine", { fg = c.gray2, bg = c.bg })
  hl("TabLineFill", { bg = c.bg })
  hl("TabLineSel", { fg = c.bg, bg = c.fg, bold = true })

  hl("WinSeparator", { fg = c.gray0, bg = c.bg })
  hl("WinBar", { fg = c.fg, bg = c.bg })
  hl("WinBarNC", { fg = c.gray2, bg = c.bg })

  -- Folds
  hl("Folded", { fg = c.gray2, bg = c.bg_alt })
  hl("FoldedIcon", { fg = c.accent, bg = c.bg_alt })

  -- Scrollbar
  hl("ScrollbarHandle", { bg = c.gray1 })
  hl("ScrollbarSearch", { bg = c.yellow })
  hl("ScrollbarError", { bg = c.error })
  hl("ScrollbarWarn", { bg = c.warn })
  hl("ScrollbarInfo", { bg = c.info })
  hl("ScrollbarHint", { bg = c.hint })
  hl("ScrollbarMisc", { bg = c.purple })

  -- Syntax
  hl("Comment", { fg = c.gray2, italic = true })
  hl("Constant", { fg = c.cyan })
  hl("String", { fg = c.green })
  hl("Character", { fg = c.green })
  hl("Number", { fg = c.cyan })
  hl("Boolean", { fg = c.cyan })
  hl("Float", { fg = c.cyan })

  hl("Identifier", { fg = c.fg })
  hl("Function", { fg = c.blue })
  hl("Method", { fg = c.blue })
  hl("Field", { fg = c.fg })
  hl("Property", { fg = c.fg })
  hl("Parameter", { fg = c.pink, italic = true })

  hl("Statement", { fg = c.purple })
  hl("Conditional", { fg = c.purple })
  hl("Repeat", { fg = c.purple })
  hl("Label", { fg = c.purple })
  hl("Operator", { fg = c.fg })
  hl("Keyword", { fg = c.purple })
  hl("Exception", { fg = c.purple })

  hl("PreProc", { fg = c.yellow })
  hl("Include", { fg = c.purple })
  hl("Define", { fg = c.purple })
  hl("Macro", { fg = c.yellow })
  hl("PreCondit", { fg = c.yellow })

  hl("Type", { fg = c.yellow })
  hl("StorageClass", { fg = c.purple })
  hl("Structure", { fg = c.yellow })
  hl("Typedef", { fg = c.yellow })

  hl("Special", { fg = c.accent })
  hl("SpecialChar", { fg = c.accent })
  hl("Tag", { fg = c.accent })
  hl("Delimiter", { fg = c.fg_dim })
  hl("SpecialComment", { fg = c.gray2, italic = true })
  hl("Debug", { fg = c.red })

  hl("Underlined", { underline = true })
  hl("Bold", { bold = true })
  hl("Italic", { italic = true })
  hl("Error", { fg = c.error })
  hl("Todo", { fg = c.accent, bg = c.bg_high, bold = true })

  -- Diagnostic
  hl("DiagnosticError", { fg = c.error })
  hl("DiagnosticWarn", { fg = c.warn })
  hl("DiagnosticInfo", { fg = c.info })
  hl("DiagnosticHint", { fg = c.hint })
  hl("DiagnosticOk", { fg = c.green })

  hl("DiagnosticVirtualTextError", { fg = c.error, bg = c.diff_delete })
  hl("DiagnosticVirtualTextWarn", { fg = c.warn, bg = c.diff_change })
  hl("DiagnosticVirtualTextInfo", { fg = c.info, bg = c.diff_change })
  hl("DiagnosticVirtualTextHint", { fg = c.hint, bg = c.diff_change })

  hl("DiagnosticUnderlineError", { undercurl = true, sp = c.error })
  hl("DiagnosticUnderlineWarn", { undercurl = true, sp = c.warn })
  hl("DiagnosticUnderlineInfo", { undercurl = true, sp = c.info })
  hl("DiagnosticUnderlineHint", { undercurl = true, sp = c.hint })

  hl("DiagnosticSignError", { fg = c.error, bg = c.bg })
  hl("DiagnosticSignWarn", { fg = c.warn, bg = c.bg })
  hl("DiagnosticSignInfo", { fg = c.info, bg = c.bg })
  hl("DiagnosticSignHint", { fg = c.hint, bg = c.bg })

  hl("DiagnosticFloatingError", { fg = c.error, bg = c.bg_alt })
  hl("DiagnosticFloatingWarn", { fg = c.warn, bg = c.bg_alt })
  hl("DiagnosticFloatingInfo", { fg = c.info, bg = c.bg_alt })
  hl("DiagnosticFloatingHint", { fg = c.hint, bg = c.bg_alt })

  -- LSP
  hl("LspReferenceText", { bg = c.bg_high })
  hl("LspReferenceRead", { bg = c.bg_high })
  hl("LspReferenceWrite", { bg = c.bg_high, underline = true })
  hl("LspCodeLens", { fg = c.gray2 })
  hl("LspCodeLensSeparator", { fg = c.gray1 })
  hl("LspSignatureActiveParameter", { fg = c.accent, bold = true })

  -- Treesitter
  hl("@variable", { fg = c.fg })
  hl("@variable.builtin", { fg = c.pink, italic = true })
  hl("@variable.parameter", { fg = c.pink, italic = true })
  hl("@variable.member", { fg = c.fg })
  hl("@constant", { fg = c.cyan })
  hl("@constant.builtin", { fg = c.cyan })
  hl("@constant.macro", { fg = c.yellow })
  hl("@module", { fg = c.yellow })
  hl("@label", { fg = c.purple })
  hl("@string", { fg = c.green })
  hl("@string.documentation", { fg = c.gray2, italic = true })
  hl("@string.regexp", { fg = c.orange })
  hl("@string.escape", { fg = c.orange })
  hl("@string.special", { fg = c.accent })
  hl("@character", { fg = c.green })
  hl("@character.special", { fg = c.accent })
  hl("@boolean", { fg = c.cyan })
  hl("@number", { fg = c.cyan })
  hl("@number.float", { fg = c.cyan })
  hl("@type", { fg = c.yellow })
  hl("@type.builtin", { fg = c.yellow })
  hl("@type.definition", { fg = c.yellow })
  hl("@attribute", { fg = c.yellow })
  hl("@property", { fg = c.fg })
  hl("@function", { fg = c.blue })
  hl("@function.builtin", { fg = c.blue })
  hl("@function.call", { fg = c.blue })
  hl("@function.macro", { fg = c.yellow })
  hl("@function.method", { fg = c.blue })
  hl("@function.method.call", { fg = c.blue })
  hl("@constructor", { fg = c.yellow })
  hl("@operator", { fg = c.fg })
  hl("@keyword", { fg = c.purple })
  hl("@keyword.coroutine", { fg = c.purple })
  hl("@keyword.function", { fg = c.purple })
  hl("@keyword.operator", { fg = c.purple })
  hl("@keyword.import", { fg = c.purple })
  hl("@keyword.type", { fg = c.purple })
  hl("@keyword.modifier", { fg = c.purple })
  hl("@keyword.repeat", { fg = c.purple })
  hl("@keyword.return", { fg = c.purple })
  hl("@keyword.debug", { fg = c.red })
  hl("@keyword.exception", { fg = c.purple })
  hl("@keyword.conditional", { fg = c.purple })
  hl("@keyword.conditional.ternary", { fg = c.purple })
  hl("@keyword.directive", { fg = c.yellow })
  hl("@keyword.directive.define", { fg = c.yellow })
  hl("@punctuation.delimiter", { fg = c.fg_dim })
  hl("@punctuation.bracket", { fg = c.fg_dim })
  hl("@punctuation.special", { fg = c.accent })
  hl("@comment", { fg = c.gray2, italic = true })
  hl("@comment.documentation", { fg = c.gray2, italic = true })
  hl("@comment.error", { fg = c.error, bold = true })
  hl("@comment.warning", { fg = c.warn, bold = true })
  hl("@comment.todo", { fg = c.accent, bg = c.bg_high, bold = true })
  hl("@comment.note", { fg = c.info, bold = true })
  hl("@tag", { fg = c.accent })
  hl("@tag.builtin", { fg = c.accent })
  hl("@tag.attribute", { fg = c.yellow })
  hl("@tag.delimiter", { fg = c.fg_dim })
  hl("@text", { fg = c.fg })
  hl("@text.strong", { bold = true })
  hl("@text.emphasis", { italic = true })
  hl("@text.underline", { underline = true })
  hl("@text.strike", { strikethrough = true })
  hl("@text.title", { fg = c.fg, bold = true })
  hl("@text.literal", { fg = c.cyan })
  hl("@text.uri", { fg = c.cyan, underline = true })
  hl("@text.math", { fg = c.yellow })
  hl("@text.environment", { fg = c.purple })
  hl("@text.environment.name", { fg = c.yellow })
  hl("@text.reference", { fg = c.cyan })
  hl("@text.todo", { fg = c.accent, bg = c.bg_high, bold = true })
  hl("@text.note", { fg = c.info, bold = true })
  hl("@text.warning", { fg = c.warn, bold = true })
  hl("@text.danger", { fg = c.error, bold = true })

  -- Diff
  hl("DiffAdd", { bg = c.diff_add })
  hl("DiffDelete", { bg = c.diff_delete })
  hl("DiffChange", { bg = c.diff_change })
  hl("DiffText", { bg = c.diff_text })

  -- Git
  hl("GitSignsAdd", { fg = c.git_add })
  hl("GitSignsChange", { fg = c.git_change })
  hl("GitSignsDelete", { fg = c.git_delete })
  hl("GitSignsAddNr", { fg = c.git_add })
  hl("GitSignsChangeNr", { fg = c.git_change })
  hl("GitSignsDeleteNr", { fg = c.git_delete })
  hl("GitSignsAddLn", { bg = c.diff_add })
  hl("GitSignsChangeLn", { bg = c.diff_change })
  hl("GitSignsDeleteLn", { bg = c.diff_delete })

  -- Telescope
  hl("TelescopeNormal", { fg = c.fg, bg = c.bg })
  hl("TelescopeBorder", { fg = c.gray0, bg = c.bg })
  hl("TelescopePromptNormal", { fg = c.fg, bg = c.bg_alt })
  hl("TelescopePromptBorder", { fg = c.accent, bg = c.bg_alt })
  hl("TelescopePromptTitle", { fg = c.bg, bg = c.accent, bold = true })
  hl("TelescopeResultsTitle", { fg = c.gray2, bg = c.bg })
  hl("TelescopePreviewTitle", { fg = c.gray2, bg = c.bg })
  hl("TelescopeSelection", { fg = c.bg, bg = c.fg })
  hl("TelescopeSelectionCaret", { fg = c.accent, bg = c.fg })
  hl("TelescopeMultiSelection", { fg = c.accent, bg = c.bg_high })
  hl("TelescopeMatching", { fg = c.accent, bold = true })
  hl("TelescopePromptPrefix", { fg = c.accent })

  -- Lualine handled by lualine config

  -- Bufferline
  hl("BufferLineFill", { bg = c.bg })
  hl("BufferLineBackground", { fg = c.gray2, bg = c.bg })
  hl("BufferLineBufferVisible", { fg = c.fg, bg = c.bg })
  hl("BufferLineBufferSelected", { fg = c.bg, bg = c.fg, bold = true })
  hl("BufferLineSeparator", { fg = c.gray0, bg = c.bg })
  hl("BufferLineSeparatorVisible", { fg = c.gray0, bg = c.bg })
  hl("BufferLineSeparatorSelected", { fg = c.fg, bg = c.fg })
  hl("BufferLineIndicatorSelected", { fg = c.accent, bg = c.fg })
  hl("BufferLineModified", { fg = c.accent, bg = c.bg })
  hl("BufferLineModifiedVisible", { fg = c.accent, bg = c.bg })
  hl("BufferLineModifiedSelected", { fg = c.accent, bg = c.fg })
  hl("BufferLineDevIcon", { fg = c.gray2, bg = c.bg })
  hl("BufferLineDevIconVisible", { fg = c.fg, bg = c.bg })
  hl("BufferLineDevIconSelected", { fg = c.bg, bg = c.fg })

  -- Indent Blankline
  hl("IblIndent", { fg = c.gray0, nocombine = true })
  hl("IblScope", { fg = c.accent, nocombine = true })
  hl("IblWhitespace", { fg = c.gray0, nocombine = true })

  -- Which-key
  hl("WhichKey", { fg = c.accent })
  hl("WhichKeyGroup", { fg = c.blue })
  hl("WhichKeyDesc", { fg = c.fg })
  hl("WhichKeySeperator", { fg = c.gray1 })
  hl("WhichKeyFloat", { bg = c.bg_alt })
  hl("WhichKeyValue", { fg = c.gray2 })

  -- Notify
  hl("NotifyBackground", { bg = c.bg })
  hl("NotifyERRORBorder", { fg = c.error })
  hl("NotifyWARNBorder", { fg = c.warn })
  hl("NotifyINFOBorder", { fg = c.info })
  hl("NotifyDEBUGBorder", { fg = c.gray2 })
  hl("NotifyTRACEBorder", { fg = c.purple })
  hl("NotifyERRORIcon", { fg = c.error })
  hl("NotifyWARNIcon", { fg = c.warn })
  hl("NotifyINFOIcon", { fg = c.info })
  hl("NotifyDEBUGIcon", { fg = c.gray2 })
  hl("NotifyTRACEIcon", { fg = c.purple })
  hl("NotifyERRORTitle", { fg = c.error })
  hl("NotifyWARNTitle", { fg = c.warn })
  hl("NotifyINFOTitle", { fg = c.info })
  hl("NotifyDEBUGTitle", { fg = c.gray2 })
  hl("NotifyTRACETitle", { fg = c.purple })

  -- Noice
  hl("NoicePopupmenu", { fg = c.fg, bg = c.bg_alt })
  hl("NoicePopupmenuSelected", { fg = c.bg, bg = c.fg })
  hl("NoicePopupmenuBorder", { fg = c.gray0, bg = c.bg_alt })

  -- Lazy
  hl("LazyNormal", { fg = c.fg, bg = c.bg })
  hl("LazyButton", { fg = c.gray2, bg = c.bg_alt })
  hl("LazyButtonActive", { fg = c.bg, bg = c.fg })
  hl("LazyH1", { fg = c.bg, bg = c.accent, bold = true })
  hl("LazyH2", { fg = c.accent, bold = true })
  hl("LazyReasonPlugin", { fg = c.purple })
  hl("LazyReasonEvent", { fg = c.blue })
  hl("LazyReasonCmd", { fg = c.yellow })
  hl("LazyReasonFt", { fg = c.green })
  hl("LazyReasonKeys", { fg = c.orange })
  hl("LazyReasonStart", { fg = c.red })
  hl("LazyReasonImport", { fg = c.cyan })
  hl("LazyReasonRuntime", { fg = c.pink })
  hl("LazyReasonSource", { fg = c.gray2 })
  hl("LazySpecial", { fg = c.accent })
  hl("LazyProgressTodo", { fg = c.gray0 })
  hl("LazyProgressDone", { fg = c.accent })

  -- Mason
  hl("MasonNormal", { fg = c.fg, bg = c.bg })
  hl("MasonHeader", { fg = c.bg, bg = c.accent, bold = true })
  hl("MasonHeaderSecondary", { fg = c.accent, bg = c.bg_high, bold = true })
  hl("MasonHighlight", { fg = c.accent })
  hl("MasonHighlightBlock", { fg = c.bg, bg = c.accent })
  hl("MasonHighlightBlockBold", { fg = c.bg, bg = c.accent, bold = true })
  hl("MasonMuted", { fg = c.gray2 })
  hl("MasonMutedBlock", { fg = c.gray2, bg = c.bg_high })

  -- Cmp
  hl("CmpItemAbbr", { fg = c.fg })
  hl("CmpItemAbbrDeprecated", { fg = c.gray1, strikethrough = true })
  hl("CmpItemAbbrMatch", { fg = c.accent, bold = true })
  hl("CmpItemAbbrMatchFuzzy", { fg = c.accent, bold = true })
  hl("CmpItemKind", { fg = c.cyan })
  hl("CmpItemKindFunction", { fg = c.blue })
  hl("CmpItemKindMethod", { fg = c.blue })
  hl("CmpItemKindConstructor", { fg = c.yellow })
  hl("CmpItemKindClass", { fg = c.yellow })
  hl("CmpItemKindStruct", { fg = c.yellow })
  hl("CmpItemKindInterface", { fg = c.yellow })
  hl("CmpItemKindModule", { fg = c.yellow })
  hl("CmpItemKindProperty", { fg = c.fg })
  hl("CmpItemKindField", { fg = c.fg })
  hl("CmpItemKindVariable", { fg = c.fg })
  hl("CmpItemKindConstant", { fg = c.cyan })
  hl("CmpItemKindEnum", { fg = c.yellow })
  hl("CmpItemKindKeyword", { fg = c.purple })
  hl("CmpItemKindSnippet", { fg = c.orange })
  hl("CmpItemKindColor", { fg = c.accent })
  hl("CmpItemKindFile", { fg = c.blue })
  hl("CmpItemKindReference", { fg = c.cyan })
  hl("CmpItemKindFolder", { fg = c.blue })
  hl("CmpItemKindEnumMember", { fg = c.cyan })
  hl("CmpItemKindOperator", { fg = c.fg })
  hl("CmpItemKindTypeParameter", { fg = c.yellow })
  hl("CmpItemKindUnit", { fg = c.cyan })
  hl("CmpItemKindValue", { fg = c.cyan })
  hl("CmpItemKindEvent", { fg = c.purple })
  hl("CmpItemKindText", { fg = c.fg })
  hl("CmpItemKindUnit", { fg = c.cyan })
  hl("CmpItemMenu", { fg = c.gray2 })

  -- Snacks (if used)
  hl("SnacksDashboardHeader", { fg = c.accent })
  hl("SnacksDashboardIcon", { fg = c.accent })
  hl("SnacksDashboardDesc", { fg = c.fg })
  hl("SnacksDashboardKey", { fg = c.blue })
  hl("SnacksDashboardFooter", { fg = c.gray2 })

  -- Alpha (dashboard)
  hl("AlphaHeader", { fg = c.accent })
  hl("AlphaButtons", { fg = c.fg })
  hl("AlphaShortcut", { fg = c.blue })
  hl("AlphaFooter", { fg = c.gray2 })

  -- Mini (if used)
  hl("MiniStatuslineModeNormal", { fg = c.bg, bg = c.fg, bold = true })
  hl("MiniStatuslineModeInsert", { fg = c.bg, bg = c.green, bold = true })
  hl("MiniStatuslineModeVisual", { fg = c.bg, bg = c.purple, bold = true })
  hl("MiniStatuslineModeReplace", { fg = c.bg, bg = c.red, bold = true })
  hl("MiniStatuslineModeCommand", { fg = c.bg, bg = c.yellow, bold = true })
  hl("MiniStatuslineModeOther", { fg = c.bg, bg = c.cyan, bold = true })
  hl("MiniStatuslineDevinfo", { fg = c.fg, bg = c.bg_alt })
  hl("MiniStatuslineFileinfo", { fg = c.fg, bg = c.bg_alt })
  hl("MiniStatuslineFilename", { fg = c.gray2, bg = c.bg })
  hl("MiniStatuslineInactive", { fg = c.gray2, bg = c.bg })

  hl("MiniTablineVisible", { fg = c.fg, bg = c.bg })
  hl("MiniTablineCurrent", { fg = c.bg, bg = c.fg, bold = true })
  hl("MiniTablineHidden", { fg = c.gray2, bg = c.bg })
  hl("MiniTablineModifiedVisible", { fg = c.accent, bg = c.bg })
  hl("MiniTablineModifiedCurrent", { fg = c.accent, bg = c.fg })
  hl("MiniTablineModifiedHidden", { fg = c.accent, bg = c.bg })
  hl("MiniTablineFill", { bg = c.bg })

  -- Trouble
  hl("TroubleNormal", { fg = c.fg, bg = c.bg })
  hl("TroubleText", { fg = c.fg })
  hl("TroubleSource", { fg = c.gray2 })
  hl("TroubleCode", { fg = c.gray2 })
  hl("TroubleIcon", { fg = c.accent })
  hl("TroubleSignError", { fg = c.error })
  hl("TroubleSignWarning", { fg = c.warn })
  hl("TroubleSignInformation", { fg = c.info })
  hl("TroubleSignHint", { fg = c.hint })
  hl("TroubleSignOther", { fg = c.purple })
  hl("TroubleIndent", { fg = c.gray0 })
  hl("TroubleFoldIcon", { fg = c.accent })
  hl("TroubleCount", { fg = c.accent, bg = c.bg_high, bold = true })
  hl("TroublePreview", { fg = c.accent, bg = c.bg_high })

  -- Gitsigns
  hl("GitSignsCurrentLineBlame", { fg = c.gray2, italic = true })
end

return M