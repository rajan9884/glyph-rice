-- Glyph: indent-blankline — Indent guides

return {
  "lukas-reineke/indent-blankline.nvim",
  event = { "BufReadPost", "BufNewFile" },
  main = "ibl",
  config = function()
    -- Nothing OS colors for indent guides (must be defined BEFORE setup)
    vim.api.nvim_set_hl(0, "IndentBlanklineChar", { fg = "#2A2A2A", nocombine = true })
    vim.api.nvim_set_hl(0, "IndentBlanklineScopeChar", { fg = "#D71921", nocombine = true })

    require("ibl").setup({
      indent = {
        char = "│",
        tab_char = "│",
        highlight = "IndentBlanklineChar",
        smart_indent_cap = true,
        priority = 2,
      },
      scope = {
        enabled = true,
        char = "│",
        highlight = "IndentBlanklineScopeChar",
        show_start = true,
        show_end = false,
        injected_languages = true,
        priority = 512,
      },
      exclude = {
        filetypes = {
          "help", "alpha", "dashboard", "neo-tree", "Trouble", "trouble",
          "lazy", "mason", "notify", "toggleterm", "terminal",
        },
        buftypes = { "terminal", "nofile", "quickfix", "prompt" },
      },
    })
  end,
}