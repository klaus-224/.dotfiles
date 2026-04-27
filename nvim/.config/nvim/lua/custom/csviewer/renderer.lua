local M = {}

local function pad_cell(cell, width)
	cell = cell or ""
	return cell .. string.rep(" ", width - #cell)
end

M.render = function(model)
	local headers = model.headers
	local rows = model.rows
	local widths = model.widths

	local pretty = {}

	-- Header row
	local header_parts = {}
	for i, cell in ipairs(headers) do
		table.insert(header_parts, pad_cell(cell, widths[i]))
	end
	table.insert(pretty, table.concat(header_parts, " │ "))

	-- Separator row
	local separator_parts = {}
	for _, width in ipairs(widths) do
		table.insert(separator_parts, string.rep("─", width))
	end

	table.insert(pretty, table.concat(separator_parts, "─┼─"))

	-- Data rows
	for _, row in ipairs(rows) do
		local parts = {}

		for i = 1, #headers do
			table.insert(parts, pad_cell(row[i], widths[i]))
		end

		table.insert(pretty, table.concat(parts, " │ "))
	end

	return pretty
end

return M
