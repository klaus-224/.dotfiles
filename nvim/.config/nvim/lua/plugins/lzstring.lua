return {
	{
		dir = "~/.dotfiles/nvim/.config/nvim/lua/custom/plugins/lzstring.nvim",
		config = function()
			require("lzstring").setup({})
		end,
	},
}
