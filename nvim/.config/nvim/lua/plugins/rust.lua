return {
	{
		"mrcjkb/rustaceanvim",
		version = "^5",
		lazy = false,
		config = function()
			vim.g.rustaceanvim = {
				server = {
					on_attach = function(_, bufnr)
						local opts = { silent = false, buffer = bufnr }
						-- rust keymaps
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
								excludeDirs = {
									"target",
									"node_modules",
									".git",
									"src-tauri/target",
									"src-tauri/node_modules",
								},
							},
							cargo = {
								targetDir = "target/rust-analyzer",
							},
							diagnostics = {
								disabled = { "unresolved-proc-macro", "macro-error" },
								enableExperimental = false,
							},
							checkOnSave = {
								command = "clippy",
								extraArgs = { "--no-deps" },
							},
							procMacro = {
								enable = false,
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
