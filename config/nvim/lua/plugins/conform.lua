-- Glyph: conform.nvim — Formatting

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_fix", "ruff_format" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        rust = { "rustfmt" },
        go = { "gofumpt", "goimports" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        zig = { "zigfmt" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        fish = { "fish_indent" },
        toml = { "taplo" },
        nix = { "nixfmt" },
        sql = { "sqlfluff" },
      },
      format_on_save = {
        timeout_ms = 2000,
        lsp_fallback = true,
      },
      formatters = {
        shfmt = { prepend_args = { "-i", "2" } },
        clang_format = { prepend_args = { "--style=file" } },
        ruff_fix = { prepend_args = { "--select", "I" } },
      },
    })
  end,
}