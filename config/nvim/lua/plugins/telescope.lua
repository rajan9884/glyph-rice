-- Glyph: Telescope — Fuzzy finder

return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        prompt_prefix = "  ",
        selection_caret = "  ",
        path_display = { "truncate" },
        sorting_strategy = "ascending",
        layout_strategy = "flex",
        layout_config = {
          horizontal = { prompt_position = "top", preview_width = 0.55, results_width = 0.8 },
          vertical = { mirror = false },
          width = 0.87,
          height = 0.80,
          preview_cutoff = 120,
        },
        mappings = {
          i = {
            ["<C-n>"] = actions.move_selection_next,
            ["<C-p>"] = actions.move_selection_previous,
            ["<C-c>"] = actions.close,
            ["<C-j>"] = actions.cycle_history_next,
            ["<C-k>"] = actions.cycle_history_prev,
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            ["<CR>"] = actions.select_default,
            ["<C-x>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
            ["<C-t>"] = actions.select_tab,
            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
          },
          n = {
            ["<C-n>"] = actions.move_selection_next,
            ["<C-p>"] = actions.move_selection_previous,
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            ["<CR>"] = actions.select_default,
            ["<C-x>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
            ["<C-t>"] = actions.select_tab,
            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["q"] = actions.close,
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            ["?"] = actions.which_key,
          },
        },
        file_ignore_patterns = { "node_modules", ".git/", "dist/", "build/", "%.lock" },
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--hidden",
          "--glob=!.git/",
        },
        border = true,
        borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        color_devicons = true,
        set_env = { COLORTERM = "truecolor" },
      },
      pickers = {
        find_files = { hidden = true, no_ignore = false },
        live_grep = { additional_args = { "--hidden", "--glob=!.git/" } },
        buffers = { sort_lastused = true, ignore_current_buffer = true },
        lsp_references = { fname_width = 100 },
        lsp_definitions = { fname_width = 100 },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
    })

    telescope.load_extension("fzf")

    -- Keymaps
    local builtin = require("telescope.builtin")
    vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
    vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
    vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "Commands" })
    vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Keymaps" })
    vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics" })
    vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Document symbols" })
    vim.keymap.set("n", "<leader>fS", builtin.lsp_workspace_symbols, { desc = "Workspace symbols" })
    vim.keymap.set("n", "<leader>fR", builtin.lsp_references, { desc = "LSP references" })
    vim.keymap.set("n", "<leader>ft", builtin.treesitter, { desc = "Treesitter" })
    vim.keymap.set("n", "<leader>fp", builtin.planets, { desc = "Planets" })
    vim.keymap.set("n", "<leader>fm", builtin.marks, { desc = "Marks" })
    vim.keymap.set("n", "<leader>f/", builtin.current_buffer_fuzzy_find, { desc = "Buffer fuzzy find" })
    vim.keymap.set("n", "<leader>f:", builtin.command_history, { desc = "Command history" })
    vim.keymap.set("n", "<leader>f'", builtin.registers, { desc = "Registers" })
  end,
}