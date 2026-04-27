local M = {}

local function pad_cell(cell, width)
	cell = cell or ""
	return cell .. string.rep(" ", width - #cell)
end

local function render_row(row, widths, column_count, separator)
	local parts = {}
	local ranges = {}

	local col = 0

	for i = 1, column_count do
		local raw = row[i] or ""
		local padded = pad_cell(raw, widths[i] or 0)

		table.insert(parts, padded)

		table.insert(ranges, {
			start_col = col,
			end_col = col + #padded,
		})

		col = col + #padded

		if i < column_count then
			col = col + #separator
		end
	end

	return table.concat(parts, separator), ranges
end

function M.render(model, opts)
	opts = opts or {}

	local separator = opts.view_separator or " │ "
	local column_count = #model.headers

	local lines = {}
	local cells = {}

	local header_line, header_ranges = render_row(model.headers, model.widths, column_count, separator)

	table.insert(lines, header_line)
	table.insert(cells, header_ranges)

	for _, row in ipairs(model.rows) do
		local line, ranges = render_row(row, model.widths, column_count, separator)

		table.insert(lines, line)
		table.insert(cells, ranges)
	end

	return {
		lines = lines,
		cells = cells,
	}
end

function M.cell_at(cells, row, col)
	local ranges = cells[row]

	if not ranges then
		return nil
	end

	for i, range in ipairs(ranges) do
		if col >= range.start_col and col < range.end_col then
			return range, i
		end
	end

	return nil
end

return M
