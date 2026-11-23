-- Glyph: Autocommands — Nothing OS aesthetic

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- General
local general = augroup("GlyphGeneral", { clear = true })

autocmd("FileType", {
  group = general,
  pattern = { "help", "man", "qf", "lspinfo", "checkhealth", "notify", "tsplayground", "PlenaryTestPopup" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})

autocmd("BufReadPost", {
  group = general,
  callback = function(event)
    local exclude = { "gitcommit", "gitrebase", "svg", "hgcommit" }
    if vim.tbl_contains(exclude, vim.bo[event.buf].filetype) then return end
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(event.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

autocmd("BufWritePre", {
  group = general,
  callback = function(event)
    if vim.bo[event.buf].filetype == "oil" then return end
    local save_cursor = vim.fn.getpos(".")
    pcall(function() vim.cmd([[%s/\s\+$//e]]) end)
    vim.fn.setpos(".", save_cursor)
  end,
})

autocmd("VimResized", {
  group = general,
  command = "tabdo wincmd =",
})

-- Highlight yank
autocmd("TextYankPost", {
  group = augroup("GlyphHighlightYank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Terminal
autocmd("TermOpen", {
  group = augroup("GlyphTerm", { clear = true }),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.cmd("startinsert")
  end,
})

-- Large files
autocmd("BufReadPre", {
  group = augroup("GlyphLargeFile", { clear = true }),
  callback = function(event)
    local max_size = 1024 * 1024 -- 1MB
    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(event.buf))
    if ok and stats and stats.size > max_size then
      vim.b.large_file = true
      vim.opt_local.syntax = "off"
      vim.opt_local.undofile = false
      vim.opt_local.swapfile = false
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.bufhidden = "unload"
      vim.opt_local.buftype = "nowrite"
      vim.notify("Large file detected: disabling syntax, undo, swap", vim.log.levels.WARN)
    end
  end,
})

-- Treesitter folds
autocmd("FileType", {
  group = augroup("GlyphFolds", { clear = true }),
  pattern = { "lua", "python", "javascript", "typescript", "json", "yaml", "toml", "rust", "go", "c", "cpp" },
  callback = function()
    vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.opt_local.foldmethod = "expr"
  end,
})