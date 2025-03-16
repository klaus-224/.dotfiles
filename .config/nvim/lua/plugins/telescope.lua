return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			local telescope = require("telescope")
			telescope.load_extension("neoclip")

			telescope.setup({
				pickers = {
				},
				file_ignore_patterns = {
					"node_modules",
					"target" -- for rust
				},
			})
			local builtin = require("telescope.builtin")

			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
			vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "Telescope search string on cursor" })
			vim.keymap.set(
				"n",
				"<leader>fs",
				builtin.lsp_document_symbols,
				{ desc = "Telescope search lsp document symbols" }
			)
			vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Telescope list warnings and errors" })
			vim.keymap.set("n", "?", builtin.current_buffer_fuzzy_find, { desc = "Fuzzy search in current buffer" })

			-- macros
			vim.keymap.set("n", "<leader>mh", ":Telescope macroscope <CR>", { desc = "Fuzzy search in current buffer" })
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			require("telescope").load_extension("ui-select")
		end,
	},
}
