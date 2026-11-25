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

    -- Auto-lint on save, open, and insert leave (skip linters missing from PATH)
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      callback = function()
        local names = lint.linters_by_ft[vim.bo.filetype] or {}
        local available = vim.tbl_filter(function(name)
          local linter = lint.linters[name]
          local cmd = type(linter) == "table" and linter.cmd or name
          if type(cmd) == "function" then
            cmd = cmd()
          end
          return type(cmd) == "string" and vim.fn.executable(cmd) == 1
        end, names)
        if #available > 0 then
          lint.try_lint(available)
        end
      end,
    })
  end,
}