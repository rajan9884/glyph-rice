-- Glyph: Alpha Dashboard — Dotmatrix/ASCII startup screen (LazyVim style)

return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- Dotmatrix NEOVIM logo — Nothing OS vibe (pure ASCII, no Unicode blocks)
    dashboard.section.header.val = {
      [[                                     ]],
      [[      __                _            ]],
      [[   /\ \ \___  ___/\   /(_)_ __ ___   ]],
      [[  /  \/ / _ \/ _ \ \ / | | '_ ` _ \  ]],
      [[ / /\  |  __| (__) \ V /| | | | | | | ]],
      [[ \_\ \/ \___|\___/ \_/ |_|_| |_| |_| ]],
      [[                                     ]],
    }

    dashboard.section.header.opts = {
      position = "center",
      hl = "AlphaHeader",
      shrink_margin = false,
    }

    -- Buttons
    dashboard.section.buttons.val = {
      dashboard.button("e", "  New File", ":ene <BAR> startinsert<CR>"),
      dashboard.button("f", "  Find File", ":Telescope find_files<CR>"),
      dashboard.button("r", "  Recent Files", ":Telescope oldfiles<CR>"),
      dashboard.button("g", "  Live Grep", ":Telescope live_grep<CR>"),
      dashboard.button("p", "  Projects", ":Telescope projects<CR>"),
      dashboard.button("s", "  Restore Session", ":lua require('persistence').load()<CR>"),
      dashboard.button("l", "  Lazy", ":Lazy<CR>"),
      dashboard.button("m", "  Mason", ":Mason<CR>"),
      dashboard.button("q", "  Quit", ":qa<CR>"),
    }

    for _, button in ipairs(dashboard.section.buttons.val) do
      button.opts.hl = "AlphaButtons"
      button.opts.hl_shortcut = "AlphaShortcut"
    end

    dashboard.section.buttons.opts = {
      spacing = 1,
    }

    -- Footer
    local function footer()
      local stats = require("lazy").stats()
      local ms = math.floor(stats.startuptime * 100) / 100
      return string.format("⚡ %d plugins loaded in %.2fms", stats.count, ms)
    end

    dashboard.section.footer.val = footer()
    dashboard.section.footer.opts = {
      position = "center",
      hl = "AlphaFooter",
    }

    -- Layout
    dashboard.config.layout = {
      { type = "padding", val = 2 },
      dashboard.section.header,
      { type = "padding", val = 2 },
      dashboard.section.buttons,
      { type = "padding", val = 2 },
      dashboard.section.footer,
    }

    -- Setup
    alpha.setup(dashboard.config)

    -- Disable folding on alpha buffer
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "alpha",
      callback = function()
        vim.opt_local.foldenable = false
        vim.opt_local.foldcolumn = "0"
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = "no"
      end,
    })

    -- Close alpha when opening a file
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "*",
      callback = function()
        if vim.bo.filetype == "alpha" and vim.fn.argc() > 0 then
          vim.cmd("bdelete")
        end
      end,
    })
  end,
}