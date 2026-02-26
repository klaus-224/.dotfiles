return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			highlight = { enable = true },
			sync_install = false,
			auto_install = true,
			modules = {},
			ignore_install = {},
			indent = { enable = true },
			ensure_installed = {
				"bash",
				"lua",
				"vim",
				"vimdoc",
				"query",
				"json",
				"jsonc",
				"javascript",
				"typescript",
				"tsx",
				"rust",
			},
		})

		-- use bash parser for zsh files
		vim.treesitter.language.register("bash", "zsh")

		-- treesitter diagnostics: surface ERROR/MISSING nodes via vim.diagnostic
		local ts_diag_ns = vim.api.nvim_create_namespace("treesitter.diagnostics")

		--- @param args vim.api.keyset.create_autocmd.callback_args
		local function diagnose(args)
			if not vim.diagnostic.is_enabled({ bufnr = args.buf }) then
				return
			end
			if vim.bo[args.buf].buftype ~= "" then
				return
			end

			local diagnostics = {}
			local parser = vim.treesitter.get_parser(args.buf, nil, { error = false })
			if not parser then
				return
			end

			parser:parse(false, function(_, trees)
				if not trees then
					return
				end
				parser:for_each_tree(function(tree, ltree)
					if ltree:lang() == "comment" or ltree:lang() == "markdown" then
						return
					end

					local root = tree:root()
					local function walk(node)
						if node:type() == "ERROR" or node:missing() then
							local lnum, col, end_lnum, end_col = node:range()

							-- collapse nested errors at same position
							local parent = node:parent()
							if parent and parent:type() == "ERROR" and parent:range() == node:range() then
								return
							end

							-- clamp large ranges to single line
							if end_lnum > lnum then
								end_lnum = lnum + 1
								end_col = 0
							end

							local message = ""
							if node:missing() then
								message = string.format("missing `%s`", node:type())
							else
								message = "syntax error"
							end

							local previous = node:prev_sibling()
							if previous and previous:type() ~= "ERROR" then
								local prev_type = previous:named() and previous:type()
									or string.format("`%s`", previous:type())
								message = message .. " after " .. prev_type
							end

							if parent and parent:type() ~= "ERROR" then
								message = message .. " in " .. parent:type()
							end

							table.insert(diagnostics, {
								source = "treesitter",
								lnum = lnum,
								end_lnum = end_lnum,
								col = col,
								end_col = end_col,
								message = message,
								code = string.format("%s-syntax", ltree:lang()),
								severity = vim.diagnostic.severity.ERROR,
							})
						end

						for child in node:iter_children() do
							walk(child)
						end
					end
					walk(root)
				end)
			end)

			vim.diagnostic.set(ts_diag_ns, args.buf, diagnostics)
		end

		vim.api.nvim_create_autocmd({ "FileType", "TextChanged", "InsertLeave" }, {
			group = vim.api.nvim_create_augroup("treesitter-diagnostics", { clear = true }),
			desc = "treesitter diagnostics",
			callback = vim.schedule_wrap(diagnose),
		})
	end,
}
