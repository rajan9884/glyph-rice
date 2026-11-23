-- Glyph: noice.nvim — Better UI for cmdline, messages, popupmenu

return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
  config = function()
    require("noice").setup({
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        hover = { enabled = true, silent = true },
        signature = { enabled = true, auto_open = { enabled = true, trigger = true } },
        message = { enabled = true, view = "notify" },
        documentation = { view = "hover" },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },
      cmdline = {
        enabled = true,
        view = "cmdline_popup",
        opts = { border = { style = "rounded" } },
        format = {
          cmdline = { pattern = "^:", icon = ":", lang = "vim" },
          search_down = { kind = "search", pattern = "^/", icon = "/", lang = "regex" },
          search_up = { kind = "search", pattern = "^%?", icon = "?", lang = "regex" },
          filter = { pattern = "^:%s*!", icon = "$", lang = "bash" },
          lua = { pattern = "^:%s*lua%s+", icon = "☾", lang = "lua" },
          help = { pattern = "^:%s*he?l?p?%s+", icon = "?" },
          input = { view = "cmdline_input", icon = "⌨" },
        },
      },
      messages = {
        enabled = true,
        view = "notify",
        view_error = "notify",
        view_warn = "notify",
        view_history = "messages",
        view_search = "virtualtext",
      },
      popupmenu = {
        enabled = true,
        backend = "nui",
        kind_icons = true,
      },
      redirect = { view = "popup", filter = { event = "msg_show" } },
      commands = {
        history = { view = "split", opts = { enter = true, format = "details" }, filter = { any = { { event = "notify" }, { event = "msg_show", kind = "" }, { event = "lsp", kind = "message" } } } },
        last = { view = "popup", opts = { enter = true, format = "details" }, filter = { any = { { event = "notify" }, { event = "msg_show", kind = "" }, { event = "lsp", kind = "message" } } } },
        errors = { view = "popup", opts = { enter = true, format = "details" }, filter = { event = "msg_show", kind = "error" } },
      },
      notify = { enabled = true, view = "notify" },
      smart_move = { enabled = true, excluded_filetypes = { "cmp_menu", "cmp_docs", "notify" } },
      throttle = 1000 / 30,
      views = {
        cmdline_popup = {
          position = { row = "50%", col = "50%" },
          size = { width = 60, height = "auto" },
          border = { style = "rounded", padding = { 0, 1 } },
          win_options = { winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder" },
        },
        popupmenu = {
          relative = "editor",
          position = { row = 8, col = "50%" },
          size = { width = 60, height = 10 },
          border = { style = "rounded", padding = { 0, 1 } },
          win_options = { winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder" },
        },
        hover = { border = { style = "rounded" } },
        split = { enter = true },
      },
      routes = {
        { filter = { event = "msg_show", kind = "", find = "written" }, opts = { skip = true } },
        { filter = { event = "msg_show", kind = "search_count" }, opts = { skip = true } },
      },
    })
  end,
}