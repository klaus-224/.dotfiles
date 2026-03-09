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
			local telescope_actions_state = require("telescope.actions.state")

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
					git_branches = {
						mappings = {
							n = {
								["<CR>"] = function(prompt_bufnr)
									local entry = telescope_actions_state.get_selected_entry()

									if #entry < 1 or entry[1] == nil then
										vim.notify("No Diff")
										return
									end

									telescope_actions.close(prompt_bufnr)

									print(entry[1])

									local file = entry.path

									vim.cmd("vsplit")
									vim.cmd("read !git show HEAD~1:" .. file)
									vim.cmd("0d_") -- remove empty first line
									vim.cmd("diffthis")
									vim.cmd("wincmd p")
									vim.cmd("diffthis")
								end,
							},
						},
					},
				},
			})

			-- KEYMAPS
			local builtin = require("telescope.builtin")

			vim.keymap.set("n", "<leader><leader>", function()
				builtin.find_files({ hidden = true, no_ignore = true, no_ignore_parent = true })
			end, { desc = "Telescope find files" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
			vim.keymap.set("n", "?", builtin.current_buffer_fuzzy_find, { desc = "Fuzzy search in current buffer" })
			vim.keymap.set("n", "<leader>ds", builtin.lsp_document_symbols, {})
			vim.keymap.set("n", "<leader>ws", builtin.lsp_workspace_symbols, {})
			vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Telescope list warnings and errors" })
			vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "List git branches" })
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
