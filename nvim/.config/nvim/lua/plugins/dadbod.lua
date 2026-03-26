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
			-- Your DBUI configuration
			vim.g.db_ui_use_nerd_fonts = 1
			vim.g.db_ui_show_database_icon = 1
			vim.g.db_ui_winwidth = 30
			vim.g.db_ui_disable_info_notifications = 1
			vim.g.dbs = {}
			vim.g.db_ui_execute_on_save = 0
			vim.g.db_ui_table_helpers = {
				duckdb = {
					List = "SELECT * FROM {table} LIMIT 200",
					Count = "SELECT COUNT(*) AS count FROM {table}",
					Describe = "DESCRIBE {table}",
					Summarize = "SUMMARIZE {table}",
					Explain = "EXPLAIN {last_query}",
					Sample = "SELECT * FROM {table} USING SAMPLE 25 ROWS",
				},
			}

			vim.api.nvim_create_user_command("DBUIT", function()
				vim.cmd("tabnew")
				vim.cmd("DBUI")
			end, {})

			vim.api.nvim_create_user_command("DuckSchema", function(opts)
				local schema = vim.trim(opts.args)
				if schema == "" then
					vim.notify("Usage: :DuckSchema <schema>", vim.log.levels.WARN)
					return
				end

				vim.cmd(("silent DB USE %s"):format(schema))
				vim.notify(("DuckDB schema set to %s"):format(schema))
			end, { nargs = 1 })
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
