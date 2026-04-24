return {
	{
		"saghen/blink.cmp",
		dependencies = {
			"rafamadriz/friendly-snippets",
		},
		version = "1.*",
		opts = {
			keymap = {
				preset = "default",
			},
			appearance = {
				nerd_font_variant = "mono",
			},
			cmdline = {
				enabled = true,
				sources = { "buffer", "cmdline" },
				completion = { menu = { auto_show = true } },
			},
			completion = {
				keyword = {
					range = "full",
				},
				-- trigger = {
				-- 	show_on_backspace = true,
				-- 	show_on_backspace_after_insert_enter = true,
				-- 	show_on_insert = true,
				-- },
				ghost_text = {
					enabled = true,
					show_with_menu = true,
					show_with_selection = true,
				},
			},
			signature = { enabled = true },
			fuzzy = {
				implementation = "rust",
				sorts = {
					"score",
					"sort_text",
				},
			},
			sources = {
				default = {
					"buffer",
					"path",
					"lsp",
					"snippets",
					"lazydev",
				},
				providers = {
					lazydev = {
						name = "LazyDev",
						module = "lazydev.integrations.blink",
					},
					cmdline = {
						module = "blink.cmp.sources.cmdline",
					},
					omni = {
						module = "blink.cmp.sources.complete_func",
						enabled = function()
							return vim.bo.omnifunc ~= "v:lua.vim.lsp.omnifunc"
						end,
						opts = {
							complete_func = function()
								return vim.bo.omnifunc
							end,
						},
					},
				},
			},
		},
		opts_extend = { "sources.default" },
	},
}
