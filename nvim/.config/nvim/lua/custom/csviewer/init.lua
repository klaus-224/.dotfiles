local parser = require("custom.csviewer.parser")
local renderer = require("custom.csviewer.renderer")
local writer = require("custom.csviewer.writer")

-- highlight commas
vim.fn.matchadd("Comment", ",")

local M = {}

-- TODO: add write a add_delimeter cmd
M.config = {
	delimiter = ",",
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	return M
end

function M.open()
	local source_buf = vim.api.nvim_get_current_buf()
	local source_name = vim.api.nvim_buf_get_name(source_buf)

	local lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
	local model = parser.parse(lines, M.config)
	local pretty = renderer.render(model)

	vim.cmd("vnew")

	local view_buf = vim.api.nvim_get_current_buf()

	vim.bo.buftype = "acwrite"
	vim.bo.bufhidden = "wipe"
	vim.bo.swapfile = false
	vim.bo.modifiable = true
	vim.bo.filetype = "csvview"

	vim.opt_local.wrap = false
	vim.opt_local.list = false
	vim.opt_local.cursorline = true
	vim.opt_local.cursorcolumn = true
	vim.opt_local.sidescroll = 1
	vim.opt_local.sidescrolloff = 8

	vim.api.nvim_buf_set_name(view_buf, source_name .. ".csvview")
	vim.api.nvim_buf_set_lines(view_buf, 0, -1, false, pretty)
	vim.bo.modified = false

	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = view_buf,
		callback = function()
			local view_lines = vim.api.nvim_buf_get_lines(view_buf, 0, -1, false)
			local csv_lines = writer.to_csv(view_lines, M.config)

			vim.api.nvim_buf_set_lines(source_buf, 0, -1, false, csv_lines)

			vim.api.nvim_buf_call(source_buf, function()
				vim.cmd("write")
			end)

			vim.bo[view_buf].modified = false
		end,
	})
end

return M
