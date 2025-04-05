return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			local telescope = require("telescope")

			-- configuration
			telescope.setup({
				defaults = {
					mappings = {
						n = {
							["q"] = require("telescope.actions").close,
						},
					},
					file_ignore_patterns = {
						"^node_modules/",
						"^target/",
						"^.git/",
					},
				},
			})

			-- keymaps
			local builtin = require("telescope.builtin")

			local find_files = function()
				builtin.find_files({ hidden = true })
			end

			vim.keymap.set("n", "<leader>ff", find_files, { desc = "Telescope find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
			vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "Telescope search string on cursor" })
			vim.keymap.set("n", "?", builtin.current_buffer_fuzzy_find, { desc = "Fuzzy search in current buffer" })
			vim.keymap.set(
				"n",
				"<leader>fs",
				builtin.lsp_document_symbols,
				{ desc = "Telescope search lsp document symbols" }
			)
			vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Telescope list warnings and errors" })
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
