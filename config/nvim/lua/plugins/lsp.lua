-- Glyph: LSP — Language Server Protocol setup (native vim.lsp.config API)

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
    "b0o/schemastore.nvim",
  },
  config = function()
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    -- Capabilities
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
    capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    capabilities.textDocument.completion.completionItem.resolveSupport = { properties = { "documentation", "detail", "additionalTextEdits" } }

    -- Diagnostics signs
    local signs = { Error = "✘", Warn = "▲", Hint = "◆", Info = "●" }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end

    vim.diagnostic.config({
      virtual_text = { spacing = 4, prefix = "●", source = "if_many" },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      float = { border = "rounded", source = "if_many", header = "", prefix = "" },
    })

    -- LSP attach function
    local on_attach = function(client, bufnr)
      local opts = { buffer = bufnr, silent = true }

      -- Keymaps
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
      vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "Go to type definition" }))
      vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
      vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover" }))
      vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
      vim.keymap.set("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, vim.tbl_extend("force", opts, { desc = "Format" }))
      vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Line diagnostics" }))
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "Prev diagnostic" }))
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))

      -- Inlay hints
      if client:supports_method("textDocument/inlayHint") then
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      end

      -- Document highlight
      if client:supports_method("textDocument/documentHighlight") then
        local group = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = false })
        vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
          group = group,
          buffer = bufnr,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
          group = group,
          buffer = bufnr,
          callback = vim.lsp.buf.clear_references,
        })
      end
    end

    -- Server configurations
    local servers = {
      lua_ls = {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            completion = { callSnippet = "Replace" },
            telemetry = { enable = false },
            diagnostics = { globals = { "vim" } },
            format = { enable = false },
            hint = { enable = true, arrayIndex = "Disable" },
          },
        },
      },
      pyright = {
        settings = {
          python = {
            analysis = { autoSearchPaths = true, useLibraryCodeForTypes = true, typeCheckingMode = "basic" },
          },
        },
      },
      ts_ls = {
        settings = {
          typescript = { inlayHints = { includeInlayParameterNameHints = "all", includeInlayParameterNameHintsWhenArgumentMatchesName = false, includeInlayFunctionParameterTypeHints = true, includeInlayVariableTypeHints = true, includeInlayPropertyDeclarationTypeHints = true, includeInlayFunctionLikeReturnTypeHints = true, includeInlayEnumMemberValueHints = true } },
          javascript = { inlayHints = { includeInlayParameterNameHints = "all", includeInlayParameterNameHintsWhenArgumentMatchesName = false, includeInlayFunctionParameterTypeHints = true, includeInlayVariableTypeHints = true, includeInlayPropertyDeclarationTypeHints = true, includeInlayFunctionLikeReturnTypeHints = true, includeInlayEnumMemberValueHints = true } },
        },
      },
      jsonls = {
        settings = { json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } } },
      },
      yamlls = {
        settings = { yaml = { schemas = require("schemastore").yaml.schemas(), keyOrdering = false } },
      },
      dockerls = {},
      docker_compose_language_service = {},
      bashls = {},
      marksman = {},
      cssls = {},
      html = {},
      tailwindcss = {},
      clangd = {
        cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed", "--header-insertion=iwyu" },
      },
      gopls = {
        settings = { gopls = { analyses = { unusedparams = true }, staticcheck = true, gofumpt = true } },
      },
      hyprls = {},
    }

    -- Setup mason
    require("mason").setup({
      ui = {
        border = "rounded",
        backdrop = 100,
        icons = { package_installed = "✓", package_pending = "⟳", package_uninstalled = "✗" },
      },
    })

    -- Setup mason-lspconfig (handles automatic installation)
    require("mason-lspconfig").setup({
      ensure_installed = vim.tbl_keys(servers),
      automatic_installation = true,
    })

    -- Configure servers using native vim.lsp.config API (neovim 0.11+)
    for server, config in pairs(servers) do
      config.capabilities = capabilities
      config.on_attach = on_attach
      vim.lsp.config(server, config)
      vim.lsp.enable(server)
    end

    -- Additional LSP keymaps
    vim.keymap.set("n", "<leader>li", "<cmd>LspInfo<CR>", { desc = "LSP Info" })
    vim.keymap.set("n", "<leader>lI", "<cmd>Mason<CR>", { desc = "Mason" })
    vim.keymap.set("n", "<leader>lr", "<cmd>LspRestart<CR>", { desc = "Restart LSP" })
  end,
}