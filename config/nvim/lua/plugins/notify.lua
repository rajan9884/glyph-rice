-- Glyph: nvim-notify — Notifications

return {
  "rcarriga/nvim-notify",
  event = "VeryLazy",
  config = function()
    require("notify").setup({
      stages = "fade_in_slide_out",
      timeout = 3000,
      background_colour = "#000000",
      render = "minimal",
      max_width = 60,
      top_down = true,
      minimum_width = 50,
      fps = 30,
      icons = {
        ERROR = "✘",
        WARN = "▲",
        INFO = "◆",
        DEBUG = "●",
        TRACE = "✦",
      },
    })
    vim.notify = require("notify")
  end,
}