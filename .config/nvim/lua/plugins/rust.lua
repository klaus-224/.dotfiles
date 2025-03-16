return {
	{
		"mrcjkb/rustaceanvim",
		version = "^5",
		lazy = false, -- This plugin is already lazy
		config = function()
			vim.g.rustaceanvim = {
				server = {
					on_attach = function(_, bufnr)
						local opts = { silent = false, buffer = bufnr }

						-- Replace the default LSP ones with the improved rustaceannvim versions.
						vim.keymap.set("n", "K", function()
							vim.cmd.RustLsp({ "hover", "actions" })
						end, opts)
						vim.keymap.set("n", "<leader>ca", function()
							vim.cmd.RustLsp("codeAction")
						end, opts)
						vim.keymap.set("n", "<leader>vT", function()
							vim.cmd.RustLsp("testables")
						end, opts)
						vim.keymap.set("n", "<leader>vE", function()
							vim.cmd.RustLsp("explainError")
						end, opts)
						vim.keymap.set("n", "<leader>vC", function()
							vim.cmd.RustLsp("openCargo")
						end, opts)
					end,
					settings = {
						["rust-analyzer"] = {
							files = {
								excludeDirs = { "target", "node_modules", ".git", ".nx", ".verdaccio" },
							},
							rustfmt = {
								extraArgs = { "+nightly" },
							},
						},
					},
				},
			}
		end,
	},
	{
		"rust-lang/rust.vim",
		ft = "rust",
		init = function()
			vim.g.rustfmt_autosave = 1
		end,
	},
}
