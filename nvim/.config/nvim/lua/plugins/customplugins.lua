return {
	{
	dir = "~/.dotfiles/nvim/.config/nvim/lua/custom/plugins/git-pr.nvim",
	config = function()
			-- require("git-pr").setup()
			require("git-pr").setup_commands()
	end
	},
	{
	dir = "~/.dotfiles/nvim/.config/nvim/lua/custom/plugins/pr-diff-loclist.nvim",
	config = function()
			require("pr-diff-loclist").setup()
	end
	}
}
