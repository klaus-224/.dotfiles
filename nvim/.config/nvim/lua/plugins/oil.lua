---@module "lazy"
---@type LazySpec
return {
	{
		"stevearc/oil.nvim",
		dependencies = {
			{
				"malewicz1337/oil-git.nvim",
				dependencies = { "stevearc/oil.nvim" },
				opts = {
					show_file_highlights = true,
					show_directory_highlights = false,
					show_ignored_files = true,
				},
			},
		},
		lazy = false,
		config = function()
			local oil = require("oil")

			oil.setup(
				---@module 'oil'
				---@type oil.SetupOpts
				{
					delete_to_trash = true,
					view_options = {
						show_hidden = true,
					},
					use_default_keymaps = false,
					keymaps = {
						["<CR>"] = { "actions.select" },
						["gv"] = { "actions.select", opts = { vertical = true } },
						["gh"] = { "actions.select", opts = { horizontal = true } },
						["gq"] = { "actions.send_to_qflist", opts = { action = "a", target = "qflist" } },
					},
				}
			)
			vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
		end,
	},
	-- diagnostics in oil
	{
		"JezerM/oil-lsp-diagnostics.nvim",
		dependencies = { "stevearc/oil.nvim" },
		opts = {},
	},
	{ "malewicz1337/oil-git.nvim", dependencies = { "stevearc/oil.nvim" } },
}
