-- Glyph: Bufferline — Nothing OS tabline

return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("bufferline").setup({
      options = {
        mode = "buffers",
        numbers = "none",
        close_command = "bdelete! %d",
        right_mouse_command = "bdelete! %d",
        left_mouse_command = "buffer %d",
        middle_mouse_command = nil,
        indicator = {
          icon = "▎",
          style = "icon",
        },
        buffer_close_icon = "✕",
        modified_icon = "●",
        close_icon = "✕",
        left_trunc_marker = "◀",
        right_trunc_marker = "▶",
        max_name_length = 18,
        max_prefix_length = 15,
        truncate_names = true,
        tab_size = 18,
        diagnostics = "nvim_lsp",
        diagnostics_update_in_insert = false,
        diagnostics_indicator = function(count, level, diagnostics_dict, context)
          local icon = level:match("error") and "✘ " or (level:match("warning") and "▲ " or "● ")
          return " " .. icon .. count
        end,
        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            text_align = "center",
            separator = true,
          },
        },
        color_icons = true,
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = false,
        show_tab_indicators = true,
        show_duplicate_prefix = true,
        persist_buffer_sort = true,
        separator_style = "thin",
        enforce_regular_tabs = false,
        always_show_bufferline = true,
        hover = {
          enabled = true,
          delay = 200,
          reveal = { "close" },
        },
        sort_by = "insert_after_current",
      },
      highlights = {
        fill = { bg = "#000000" },
        background = { fg = "#8C8C8C", bg = "#000000" },
        buffer_visible = { fg = "#F2F2F2", bg = "#000000" },
        buffer_selected = { fg = "#000000", bg = "#F2F2F2", bold = true },
        separator = { fg = "#2A2A2A", bg = "#000000" },
        separator_visible = { fg = "#2A2A2A", bg = "#000000" },
        separator_selected = { fg = "#F2F2F2", bg = "#F2F2F2" },
        indicator_selected = { fg = "#D71921", bg = "#F2F2F2" },
        modified = { fg = "#D71921", bg = "#000000" },
        modified_visible = { fg = "#D71921", bg = "#000000" },
        modified_selected = { fg = "#D71921", bg = "#F2F2F2" },
        close_button = { fg = "#8C8C8C", bg = "#000000" },
        close_button_visible = { fg = "#8C8C8C", bg = "#000000" },
        close_button_selected = { fg = "#000000", bg = "#F2F2F2" },
        tab = { fg = "#8C8C8C", bg = "#000000" },
        tab_selected = { fg = "#000000", bg = "#F2F2F2", bold = true },
        tab_close = { fg = "#8C8C8C", bg = "#000000" },
      },
    })
  end,
}