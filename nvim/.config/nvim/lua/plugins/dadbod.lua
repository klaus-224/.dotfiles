return {
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true }, -- Optional
		},
		cmd = {
			"DBUI",
			"DBUIToggle",
			"DBUIAddConnection",
		},
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
			vim.g.db_ui_show_database_icon = 1
			vim.g.db_ui_winwidth = 30
			vim.g.db_ui_disable_info_notifications = 1
			vim.g.dbs = {}
			vim.g.db_ui_execute_on_save = 0

			vim.api.nvim_create_user_command("DBUIT", function()
				vim.cmd("tabnew")
				vim.cmd("DBUI")
			end, {})
		end,
	},
	{
		"saghen/blink.cmp",
		opts = {
			sources = {
				per_filetype = {
					sql = { "path", "dadbod", "buffer" },
				},
				providers = {
					dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
				},
			},
		},
	},
}
