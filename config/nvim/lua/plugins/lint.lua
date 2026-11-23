-- Glyph: nvim-lint — Linting

return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      python = { "ruff" },
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      json = { "jsonlint" },
      yaml = { "yamllint" },
      markdown = { "markdownlint" },
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      dockerfile = { "hadolint" },
      sql = { "sqlfluff" },
      lua = { "luacheck" },
      go = { "golangcilint" },
      c = { "cpplint" },
      cpp = { "cpplint" },
    }

    -- Auto-lint on save and text change
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave", "TextChanged" }, {
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}