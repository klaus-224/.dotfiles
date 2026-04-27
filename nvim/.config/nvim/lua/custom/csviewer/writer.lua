local M = {}

local function pretty_line_to_csv(line, delimiter)
	local cells = vim.split(line, "│", { plain = true })

	for i, cell in ipairs(cells) do
		cells[i] = vim.trim(cell)
	end

	return table.concat(cells, delimiter)
end

function M.to_csv(lines, opts)
	opts = opts or {}

	local csv_lines = {}

	for i, line in ipairs(lines) do
		if i ~= 2 then
			table.insert(csv_lines, pretty_line_to_csv(line, opts.delimiter))
		end
	end

	return csv_lines
end

return M
