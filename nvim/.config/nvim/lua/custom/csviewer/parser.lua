local M = {}

local function split_line(line, delimiter)
	return vim.split(line, delimiter or ",", { plain = true })
end

local function update_widths(widths, row)
	for i, cell in ipairs(row) do
		widths[i] = math.max(widths[i] or 0, #cell)
	end
end

M.parse = function(lines, opts)
	local delimiter = opts.delimiter or ","
	local headers = split_line(lines[1] or "", delimiter)

	local rows = {}
	local records = {}
	local widths = {}
	update_widths(widths, headers)

	for i = 2, #lines do
		local row = split_line(lines[i], delimiter)

		update_widths(widths, row)
		table.insert(rows, row)
	end

	return {
		headers = headers,
		rows = rows,
		records = records,
		widths = widths,
	}
end

function M.from_model(model, opts)
	opts = opts or {}

	local delimiter = opts.delimiter or ","
	local lines = {}

	table.insert(lines, table.concat(model.headers, delimiter))

	for _, row in ipairs(model.rows) do
		local cells = {}

		for i = 1, #model.headers do
			cells[i] = row[i] or ""
		end

		table.insert(lines, table.concat(cells, delimiter))
	end

	return lines
end

return M
