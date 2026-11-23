-- Glyph: Core Options — Nothing OS aesthetic

local opt = vim.opt
local g = vim.g

-- Leader
g.mapleader = " "
g.maplocalleader = "\\"

-- UI
opt.termguicolors = true
opt.background = "dark"
opt.cursorline = true
opt.cursorlineopt = "number"
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes:1"
opt.foldcolumn = "0"
opt.colorcolumn = "100"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.linebreak = true
opt.showbreak = "↪ "
opt.list = true
opt.listchars = { tab = "▸ ", trail = "·", nbsp = "␣", extends = "»", precedes = "«" }
opt.fillchars = { fold = " ", foldopen = "▾", foldsep = "│", foldclose = "▸", diff = "╱", eob = " " }
opt.pumheight = 10
opt.pumblend = 10
opt.winblend = 10
opt.conceallevel = 2
opt.concealcursor = "nc"

-- Editing
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.autowrite = true
opt.autoread = true
opt.confirm = true
opt.clipboard = "unnamedplus"
opt.mouse = "a"
opt.mousemoveevent = true
opt.virtualedit = "block"
opt.inccommand = "split"
opt.ignorecase = true
opt.smartcase = true
opt.gdefault = true

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.breakindent = true
opt.shiftround = true

-- Search
opt.hlsearch = true
opt.incsearch = true

-- Splits
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"

-- Completion
opt.completeopt = "menu,menuone,noselect,popup"
opt.wildmode = "longest:full,full"
opt.wildoptions = "pum"

-- Performance
opt.updatetime = 200
opt.timeoutlen = 300
opt.ttimeoutlen = 10
opt.redrawtime = 1500
opt.synmaxcol = 2400

-- Folding
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""

-- Diagnostics
vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = "●" },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many", header = "", prefix = "" },
})

-- Provider disables (speed)
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.loaded_node_provider = 0
g.loaded_python3_provider = 0

-- Custom diagnostic signs (Nothing OS style)
local signs = { Error = "✘", Warn = "▲", Hint = "◆", Info = "●" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end