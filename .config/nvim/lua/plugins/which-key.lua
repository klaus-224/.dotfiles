return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},
	config = function()
		local wk = require("which-key")

		wk.add({
			-- Dotnet
			{ "<leader>dn", "<cmd>DotnetUI new_item<CR>", desc = "Dotnet new item" },
			{ "<leader>dap", "<cmd>DotnetUI project package add<CR>", desc = "Dotnet add package" },
			{ "<leader>ddp", "<cmd>DotnetUI project package remove<CR>", desc = "Dotnet remove package" },
			{ "<leader>dar", "<cmd>DotnetUI project reference add<CR>", desc = "Dotnet project add reference" },
			{ "<leader>drr", "<cmd>DotnetUI project reference remove<CR>", desc = "Dotnet project remove reference" },
		})
	end,
}
