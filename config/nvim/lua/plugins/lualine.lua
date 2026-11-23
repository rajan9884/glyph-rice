-- Glyph: Lualine — Nothing OS statusline

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    -- Nothing OS colors
    local colors = {
      bg = "#000000",
      fg = "#F2F2F2",
      crimson = "#D71921",
      gray = "#8C8C8C",
      dark_gray = "#2A2A2A",
      white = "#F2F2F2",
      black = "#000000",
    }

    local theme = {
      normal = {
        a = { fg = colors.black, bg = colors.crimson, gui = "bold" },
        b = { fg = colors.white, bg = colors.dark_gray },
        c = { fg = colors.gray, bg = colors.bg },
      },
      insert = {
        a = { fg = colors.black, bg = colors.white, gui = "bold" },
        b = { fg = colors.white, bg = colors.dark_gray },
        c = { fg = colors.gray, bg = colors.bg },
      },
      visual = {
        a = { fg = colors.black, bg = colors.white, gui = "bold" },
        b = { fg = colors.white, bg = colors.dark_gray },
        c = { fg = colors.gray, bg = colors.bg },
      },
      replace = {
        a = { fg = colors.black, bg = colors.crimson, gui = "bold" },
        b = { fg = colors.white, bg = colors.dark_gray },
        c = { fg = colors.gray, bg = colors.bg },
      },
      command = {
        a = { fg = colors.black, bg = colors.white, gui = "bold" },
        b = { fg = colors.white, bg = colors.dark_gray },
        c = { fg = colors.gray, bg = colors.bg },
      },
      inactive = {
        a = { fg = colors.gray, bg = colors.bg, gui = "bold" },
        b = { fg = colors.gray, bg = colors.bg },
        c = { fg = colors.gray, bg = colors.bg },
      },
    }

    require("lualine").setup({
      options = {
        theme = theme,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = { statusline = { "alpha", "dashboard" }, winbar = { "alpha", "dashboard" } },
        ignore_focus = { "alpha", "dashboard" },
        always_divide_middle = true,
        globalstatus = true,
        refresh = { statusline = 1000, tabline = 1000, winbar = 1000 },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1, symbols = { modified = "●", readonly = "🔒", unnamed = "" } } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {},
      winbar = {},
      inactive_winbar = {},
      extensions = { "neo-tree", "lazy", "mason", "trouble" },
    })
  end,
}