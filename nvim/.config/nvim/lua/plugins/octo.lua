return {
	"pwntester/octo.nvim",
	enabled = vim.env.USER ~= "klaus224",
	requires = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("octo").setup({
			ssh_aliases = {
				["github.com-klaus-224"] = "github.com",
				["github.com-orennia-account"] = "github.com",
			},
			suppress_missing_scope = {
				projects_v2 = true,
			},
		})
	end,
}
