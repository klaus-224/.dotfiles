return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufWritePost", "InsertLeave" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			sh = { "shellcheck" },
			bash = { "shellcheck" },
			zsh = { "shellcheck" },
		}

		local shellcheck = lint.linters.shellcheck
		local default_args = shellcheck.args

		local function lint_shellcheck(bufnr)
			local ft = vim.bo[bufnr].filetype
			if ft == "zsh" then
				shellcheck.args = { "--format", "json1", "--shell=bash", "-" }
			else
				shellcheck.args = default_args
			end
			lint.try_lint("shellcheck")
			shellcheck.args = default_args
		end

		local group = vim.api.nvim_create_augroup("lint-shellcheck", { clear = true })
		vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
			group = group,
			callback = function(args)
				if vim.bo[args.buf].buftype ~= "" then
					return
				end
				if vim.bo[args.buf].filetype == "zsh" then
					lint_shellcheck(args.buf)
				end
			end,
		})
	end,
}
