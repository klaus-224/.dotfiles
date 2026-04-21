return {
	{
		"nvim-telescope/telescope.nvim",
		branch = "master",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local telescope_actions = require("telescope.actions")

			-- CONFIGURATION
			telescope.setup({
				defaults = {
					mappings = {
						n = {
							["q"] = telescope_actions.close,
						},
					},
					preview = {
						wrap = true,
						file_size_limit = 0.1,
					},
				},
				pickers = {
					find_files = {
						find_command = {
							"rg",
							"--files",
							"--glob",
							"!**/node_modules/**",
							"--glob",
							"!**/.git/**",
							"--glob",
							"!**/.turbo/**",
							"--glob",
							"!**/venv/**",
							"--glob",
							"!**/.venv/**",
							"--glob",
							"!**/site-packages/**",
							"--glob",
							"!**/target/**",
							"--glob",
							"!**/trace/**",
							"--glob",
							"!**/out/**",
							"--glob",
							"!**/.uv-cache/**",
							"--glob",
							"!**/__pycache__/**",
							"--path-separator",
							"/",
						},
					},
					live_grep = {
						additional_args = function()
							return {
								"--hidden",
								"--no-ignore",
								"--no-ignore-vcs",
								"--glob",
								"!**/node_modules/**",
								"--glob",
								"!**/.git/**",
								"--glob",
								"!**/.turbo/**",
								"--glob",
								"!**/venv/**",
								"--glob",
								"!**/.venv/**",
								"--glob",
								"!**/site-packages/**",
								"--glob",
								"!**/target/**",
								"--glob",
								"!**/trace/**",
								"--glob",
								"!**/out/**",
							}
						end,
					},
				},
			})

			-- KEYMAPS
			local builtin = require("telescope.builtin")

			vim.keymap.set("n", "<leader><leader>", function()
				builtin.find_files({ hidden = true, no_ignore = true, no_ignore_parent = true })
			end)
			vim.keymap.set("n", "?", builtin.current_buffer_fuzzy_find)
			vim.keymap.set("n", "<leader>FS", builtin.lsp_workspace_symbols)
			vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols)
			vim.keymap.set("n", "<leader>fh", builtin.help_tags)
			vim.keymap.set("n", "<leader>ff", builtin.buffers)
			vim.keymap.set("n", "<leader>li", builtin.lsp_incoming_calls)
			vim.keymap.set("n", "<leader>lo", builtin.lsp_outgoing_calls)

			require("custom.multigrep").setup()
		end,
	},
}
