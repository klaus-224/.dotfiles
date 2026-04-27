local parser = require("custom.csviewer.parser")
local renderer = require("custom.csviewer.renderer")
local writer = require("custom.csviewer.writer")

local M = {}

M.config = {
	delimiter = ",",
	separator = "│",
	view_separator = " │ ",
}

local state = {
	source_buf = nil,
	view_buf = nil,
	model = nil,
	rendered = nil,
}

-- START HELPERS
local function get_cell_starts(line)
	local starts = { 1 }
	local init = 1

	while true do
		local sep_start, sep_end = line:find(M.config.separator, init, true)

		if not sep_start then
			break
		end

		-- Assumes renderer joins cells using: " │ "
		local cell_start = sep_end + 2
		table.insert(starts, cell_start)

		init = sep_end + 1
	end

	return starts
end

local function closest_cell_start(line, col)
	local starts = get_cell_starts(line)
	local closest = starts[1] or 1

	for _, start_col in ipairs(starts) do
		if math.abs(start_col - col) < math.abs(closest - col) then
			closest = start_col
		end
	end

	return closest
end

local function current_cell_index()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1]
	local col = cursor[2]

	local _, cell_index = renderer.cell_at(state.cells, row, col)

	return row, cell_index
end

local function render_into_view(buf, model)
	local rendered = renderer.render(model, M.config)

	state.model = model
	state.rendered = rendered

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, rendered.lines)
end

local function highlight_current_cell(buf)
	local ns = vim.api.nvim_create_namespace("csviewer_cell")

	vim.api.nvim_set_hl(0, "CsviewerCell", {
		link = "Visual",
		default = true,
	})

	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1]
	local col = cursor[2]

	local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
	if not line then
		return
	end

	local line_len = #line
	local range = renderer.cell_at(state.cells, row, col)

	if not range then
		return
	end

	local start_col = math.min(range.start_col, line_len)
	local end_col = math.min(range.end_col, line_len)

	if end_col <= start_col then
		end_col = math.min(start_col + 1, line_len)
	end

	if end_col <= start_col then
		return
	end

	vim.api.nvim_buf_set_extmark(buf, ns, row - 1, start_col, {
		end_col = end_col,
		hl_group = "CsviewerCell",
		hl_mode = "combine",
	})

	vim.api.nvim_buf_set_extmark(buf, ns, row - 1, range.start_col, {
		end_col = range.end_col,
		hl_group = "CsviewerCell",
		hl_mode = "combine",
	})
end

local function view_to_rows(view_buf)
	local lines = vim.api.nvim_buf_get_lines(view_buf, 0, -1, false)
	local rows = {}

	for _, line in ipairs(lines) do
		local cells = vim.split(line, M.config.separator, { plain = true })

		for i, cell in ipairs(cells) do
			cells[i] = vim.trim(cell)
		end

		table.insert(rows, cells)
	end

	return rows
end

local function rows_to_csv(rows)
	local csv_lines = {}

	for _, row in ipairs(rows) do
		table.insert(csv_lines, table.concat(row, M.config.delimiter))
	end

	return csv_lines
end

local function render_rows(view_buf, rows)
	local csv_lines = rows_to_csv(rows)
	render_into_view(view_buf, csv_lines)
	vim.bo[view_buf].modified = true
	highlight_current_cell(view_buf)
end

-- END HELPERS

-- START OPERATIONS
function M.insert_col()
	local view_buf = state.view_buf
	local rows = view_to_rows(view_buf)
	local _, col = current_cell_index()

	if not col then
		return
	end

	for row_idx, row in ipairs(rows) do
		local value = row_idx == 1 and "new_column" or ""
		table.insert(row, col + 1, value)
	end

	render_rows(view_buf, rows)
end

function M.duplicate_col()
	local view_buf = state.view_buf
	local rows = view_to_rows(view_buf)
	local _, col = current_cell_index()

	if not col then
		return
	end

	for row_idx, row in ipairs(rows) do
		local value = row_idx == 1 and table.insert(row, col + 1, value)
	end

	render_rows(view_buf, rows)
end

function M.delete_col()
	local view_buf = state.view_buf
	local rows = view_to_rows(view_buf)
	local _, col = current_cell_index()

	if not col then
		return
	end

	for _, row in ipairs(rows) do
		table.remove(row, col)
	end

	render_rows(view_buf, rows)
end

function M.insert_row()
	local view_buf = state.view_buf
	local rows = view_to_rows(view_buf)
	local row, _ = current_cell_index()

	if not row then
		return
	end

	local column_count = #(rows[1] or {})
	local new_row = {}

	for i = 1, column_count do
		new_row[i] = ""
	end

	table.insert(rows, row + 1, new_row)

	render_rows(view_buf, rows)
end

function M.delete_row()
	local view_buf = state.view_buf
	local rows = view_to_rows(view_buf)
	local row, _ = current_cell_index()

	if not row then
		return
	end

	-- Do not delete header row
	if row == 1 then
		vim.notify("Cannot delete CSV header row", vim.log.levels.WARN)
		return
	end

	table.remove(rows, row)

	render_rows(view_buf, rows)
end

function M.jumpcol(direction)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1]
	local col = cursor[2] + 1

	local line = vim.api.nvim_get_current_line()
	local starts = get_cell_starts(line)

	if direction > 0 then
		for _, start_col in ipairs(starts) do
			if start_col > col then
				vim.api.nvim_win_set_cursor(0, { row, start_col - 1 })
				highlight_current_cell(state.view_buf)
				return
			end
		end
	else
		for i = #starts, 1, -1 do
			if starts[i] < col then
				vim.api.nvim_win_set_cursor(0, { row, starts[i] - 1 })
				highlight_current_cell(state.view_buf)
				return
			end
		end
	end
end

function M.jumprow(direction)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1]
	local col = cursor[2] + 1

	local target_row = row + direction
	local line_count = vim.api.nvim_buf_line_count(0)

	if target_row < 1 or target_row > line_count then
		return
	end

	local target_line = vim.api.nvim_buf_get_lines(0, target_row - 1, target_row, false)[1] or ""
	local target_col = closest_cell_start(target_line, col)

	vim.api.nvim_win_set_cursor(0, { target_row, target_col - 1 })
	highlight_current_cell(state.view_buf)
end

-- END OPERATIONS

-- START CONFIG
local function set_buffer_options()
	vim.bo.buftype = "acwrite"
	vim.bo.bufhidden = "wipe"
	vim.bo.swapfile = false
	vim.bo.modifiable = true
	vim.bo.filetype = "csvview"

	vim.opt_local.wrap = false
	vim.opt_local.list = false
	vim.opt_local.cursorline = true
	vim.opt_local.cursorcolumn = false
	vim.opt_local.sidescroll = 1
	vim.opt_local.sidescrolloff = 8
end

local function set_cell_highlight_autocmd(buf)
	vim.api.nvim_create_autocmd({ "CursorMoved" }, {
		buffer = buf,
		callback = function()
			highlight_current_cell(buf)
		end,
	})

	highlight_current_cell(buf)
end

local function set_write_autocmd(view_buf, source_buf)
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = view_buf,
		callback = function()
			local cursor = vim.api.nvim_win_get_cursor(0)
			local row = cursor[1]
			local col = cursor[2] + 1

			local view_lines = vim.api.nvim_buf_get_lines(view_buf, 0, -1, false)
			local csv_lines = writer.to_csv(view_lines, M.config)

			-- Update original CSV buffer
			vim.api.nvim_buf_set_lines(source_buf, 0, -1, false, csv_lines)

			-- Write original CSV buffer to disk
			vim.api.nvim_buf_call(source_buf, function()
				vim.cmd("write")
			end)

			-- Re-render view using fresh widths
			render_into_view(view_buf, csv_lines)

			local line_count = vim.api.nvim_buf_line_count(view_buf)
			local target_row = math.min(row, line_count)

			local target_line = vim.api.nvim_buf_get_lines(view_buf, target_row - 1, target_row, false)[1] or ""
			local target_col = closest_cell_start(target_line, col)

			vim.api.nvim_win_set_cursor(0, { target_row, target_col - 1 })

			vim.bo[view_buf].modified = false
			highlight_current_cell(view_buf)
		end,
	})
end

local function set_keymaps(buf)
	local map = function(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, {
			buffer = buf,
			silent = true,
			desc = desc,
		})
	end

	map("h", function()
		M.jumpcol(-1)
	end, "CSV previous column")

	map("l", function()
		M.jumpcol(1)
	end, "CSV next column")

	map("j", function()
		M.jumprow(1)
	end, "CSV next row")

	map("k", function()
		M.jumprow(-1)
	end, "CSV previous row")
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	return M
end

function M.open()
	local source_buf = vim.api.nvim_get_current_buf()
	local source_name = vim.api.nvim_buf_get_name(source_buf)
	local csv_lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)

	state.model = parser.parse(csv_lines, M.config)

	vim.cmd("enew")

	local view_buf = vim.api.nvim_get_current_buf()

	state.source_buf = source_buf
	state.view_buf = view_buf

	render_into_view(state.view_buf, state.model)
	set_buffer_options()

	local view_name = source_name ~= "" and source_name .. ".csvview" or "csvview"
	vim.api.nvim_buf_set_name(view_buf, view_name)

	vim.bo.modified = false

	set_keymaps(view_buf)
	set_write_autocmd(view_buf, source_buf)
	set_cell_highlight_autocmd(view_buf)
end
-- END CONFIG

return M
