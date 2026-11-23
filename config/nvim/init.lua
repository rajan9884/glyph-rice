-- Glyph Neovim Config — Nothing OS aesthetic
-- Black bg (#000000), White fg (#F2F2F2), Crimson accent (#D71921)

-- Disable terminal background query (fixes E1568 DSR error) - MUST be first
vim.o.background = "dark"
-- Defer termguicolors to avoid DSR query at startup
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.g.termguicolors = true
  end,
})

require("core.options")
require("core.keymaps")
require("core.autocmds")

-- Load colorscheme directly (local, not via lazy)
require("colorscheme").setup()

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" }, { "\nPress any key to exit..." } }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Auto-install treesitter parsers on first run
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  once = true,
  callback = function()
    local install = require("nvim-treesitter.install")
    install.prefer_git = false
    install.update({ with_sync = true })
  end,
})

-- Load plugins
require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = { lazy = true },
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
  rocks = { enabled = false }, -- disable luarocks (not needed)
  ui = {
    border = "rounded",
    backdrop = 100,
  },
})