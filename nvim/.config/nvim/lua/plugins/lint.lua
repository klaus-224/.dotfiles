return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufWritePost", "InsertLeave" },
	config = function()
		local lint = require("lint")

		vim.filetype.add({
			pattern = {
				["%.env"] = "dotenv",
				["%.env%..*"] = "dotenv",
			},
		})

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
			end
			lint.try_lint("shellcheck")
			shellcheck.args = default_args
		end

		local group = vim.api.nvim_create_augroup("lint-shellcheck", { clear = true })
		vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
			group = group,
			callback = function(args)
				local ft = vim.bo[args.buf].filetype
				if ft == "zsh" or ft == "sh" or ft == "bash" then
					lint_shellcheck(args.buf)
				elseif ft == "dotenv" then
					return
				end
			end,
		})
	end,
}
