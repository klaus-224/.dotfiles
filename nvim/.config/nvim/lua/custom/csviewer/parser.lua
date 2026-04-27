local M = {}

local function split_line(line, delimiter)
	return vim.split(line, delimiter or ",", { plain = true })
end

local function row_to_record(headers, row)
	local record = {}

	for i, header in ipairs(headers) do
		record[header] = row[i] or ""
	end

	return record
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
		table.insert(records, row_to_record(headers, row))
	end

	return {
		headers = headers,
		rows = rows,
		records = records,
		widths = widths,
	}
end

return M
