local M = {}

-- LSP symbol kind mapping to readable names
local symbol_kinds = {
	[1] = "File",
	[2] = "Module",
	[3] = "Namespace",
	[4] = "Package",
	[5] = "Class",
	[6] = "Method",
	[7] = "Property",
	[8] = "Field",
	[9] = "Constructor",
	[10] = "Enum",
	[11] = "Interface",
	[12] = "Function",
	[13] = "Variable",
	[14] = "Constant",
	[15] = "String",
	[16] = "Number",
	[17] = "Boolean",
	[18] = "Array",
	[19] = "Object",
	[20] = "Key",
	[21] = "Null",
	[22] = "EnumMember",
	[23] = "Struct",
	[24] = "Event",
	[25] = "Operator",
	[26] = "TypeParameter",
}

-- Get icon for symbol kind using nvim-web-devicons
local function get_symbol_icon(kind_name)
	local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
	if not devicons_ok then
		-- Fallback to hardcoded icons
		local fallback_icons = {
			File = "󰈙",
			Module = "󰕳",
			Namespace = "󰌗",
			Package = "󰏖",
			Class = "󰌗",
			Method = "󰊕",
			Property = "󰜢",
			Field = "󰜢",
			Constructor = "󰡱",
			Enum = "󰕘",
			Interface = "󰕘",
			Function = "󰊕",
			Variable = "󰀫",
			Constant = "󰏿",
			String = "󰀬",
			Number = "󰎠",
			Boolean = "◩",
			Array = "󰅪",
			Object = "󰅩",
			Key = "󰌋",
			Null = "󰟢",
			EnumMember = "󰕘",
			Struct = "󰌗",
			Event = "󰉁",
			Operator = "󰆕",
			TypeParameter = "󰊄",
		}
		return fallback_icons[kind_name] or "?"
	end

	-- Actually use devicons API to get appropriate icons
	local icon_queries = {
		File = "file",
		Module = "module.js",
		Namespace = "namespace.ts",
		Package = "package.json",
		Class = "class.java",
		Method = "method.lua",
		Function = "function.js",
		Variable = "variable.js",
		Constant = "const.js",
		Interface = "interface.ts",
		Enum = "enum.ts",
		Struct = "struct.c",
	}

	local query = icon_queries[kind_name]
	if query then
		local icon = devicons.get_icon(query)
		if icon then
			return icon
		end
	end

	-- Fallback to semantic icons with actual devicons calls where possible
	local icon_mapping = {
		File = devicons.get_icon("file") or "󰈙",
		Module = devicons.get_icon("module.js") or "󰕳",
		Namespace = "󰌗",
		Package = devicons.get_icon("package.json") or "󰏖",
		Class = "󰠱",
		Method = "󰊕",
		Property = "󰜢",
		Field = "󰜢",
		Constructor = "󰡱",
		Enum = "󰕘",
		Interface = "󰕘",
		Function = devicons.get_icon("function.js") or "󰊕",
		Variable = "󰀫",
		Constant = "󰏿",
		String = "󰀬",
		Number = "󰎠",
		Boolean = "󰨚",
		Array = "󰅪",
		Object = "󰅩",
		Key = "󰌋",
		Null = "󰟢",
		EnumMember = "󰕘",
		Struct = "󰌗",
		Event = "󰉁",
		Operator = "󰆕",
		TypeParameter = "󰊄",
	}

	local mapped_icon = icon_mapping[kind_name]
	return (type(mapped_icon) == "string" and mapped_icon) or mapped_icon or "?"
end

local state = {
	original_buf = nil,
	symbols_buf = nil,
	symbols_win = nil,
	all_symbols = {},
	filtered_symbols = {},
	current_filter = nil,
	highlight_ns = nil, -- namespace for highlighting
}

-- Parse document symbols recursively
local function parse_symbols(symbols, level, parent_name)
	level = level or 0
	parent_name = parent_name or ""
	local result = {}

	for _, symbol in ipairs(symbols) do
		local full_name = parent_name ~= "" and (parent_name .. "." .. symbol.name) or symbol.name
		local kind_name = symbol_kinds[symbol.kind] or "Unknown"
		local icon = get_symbol_icon(kind_name)

		table.insert(result, {
			name = symbol.name,
			full_name = full_name,
			kind = symbol.kind,
			kind_name = kind_name,
			icon = icon,
			level = level,
			range = symbol.range or symbol.location.range,
			line = (symbol.range or symbol.location.range).start.line + 1,
		})

		-- Parse children recursively
		if symbol.children then
			local children = parse_symbols(symbol.children, level + 1, full_name)
			for _, child in ipairs(children) do
				table.insert(result, child)
			end
		end
	end

	return result
end

-- Create the symbols buffer content
local function create_buffer_content(symbols, filter_text)
	local lines = {}

	-- Header with filter info
	if filter_text then
		table.insert(lines, "Document Symbols (filtered: " .. filter_text .. ")")
	else
		table.insert(lines, "Document Symbols")
	end
	table.insert(lines, "")

	-- Symbol lines
	for _, symbol in ipairs(symbols) do
		local indent = string.rep("  ", symbol.level)
		local line = string.format("%s%s [%s] %s (line %d)",
			indent, symbol.icon, symbol.kind_name, symbol.name, symbol.line)
		table.insert(lines, line)
	end

	return lines
end

-- Update the symbols buffer
local function update_symbols_buffer()
	if not state.symbols_buf or not vim.api.nvim_buf_is_valid(state.symbols_buf) then
		return
	end

	local symbols_to_show = state.current_filter and state.filtered_symbols or state.all_symbols
	local lines = create_buffer_content(symbols_to_show, state.current_filter)

	vim.api.nvim_buf_set_option(state.symbols_buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(state.symbols_buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(state.symbols_buf, "modifiable", false)
end

-- Filter symbols by kind
local function filter_symbols(filter_type)
	if not filter_type then
		state.current_filter = nil
		state.filtered_symbols = {}
		update_symbols_buffer()
		return
	end

	-- Find matching kind number
	local target_kind = nil
	for kind_num, kind_name in pairs(symbol_kinds) do
		if kind_name:lower() == filter_type:lower() then
			target_kind = kind_num
			break
		end
	end

	if not target_kind then
		vim.notify("Unknown symbol type: " .. filter_type, vim.log.levels.ERROR)
		return
	end

	state.current_filter = symbol_kinds[target_kind]
	state.filtered_symbols = {}

	for _, symbol in ipairs(state.all_symbols) do
		if symbol.kind == target_kind then
			table.insert(state.filtered_symbols, symbol)
		end
	end

	update_symbols_buffer()
end

-- Jump to symbol at cursor (used for both Enter key and live preview)
local function jump_to_symbol(preview_mode)
	preview_mode = preview_mode or false
	local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

	-- Skip header lines
	if cursor_line <= 2 then
		return
	end

	local symbol_index = cursor_line - 2
	local symbols_to_use = state.current_filter and state.filtered_symbols or state.all_symbols

	if symbol_index > 0 and symbol_index <= #symbols_to_use then
		local symbol = symbols_to_use[symbol_index]

		-- Find the original buffer window
		local original_win = nil
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_buf(win) == state.original_buf then
				original_win = win
				break
			end
		end

		if original_win then
			-- Clear previous highlights
			if state.highlight_ns then
				vim.api.nvim_buf_clear_namespace(state.original_buf, state.highlight_ns, 0, -1)
			end

			-- For preview mode, don't change current window, just update the original buffer
			if preview_mode then
				vim.api.nvim_win_set_cursor(original_win, { symbol.line, symbol.range.start.character })
				-- Center the line in the original window
				vim.api.nvim_buf_call(state.original_buf, function()
					vim.cmd("normal! zz")
				end)

				-- Add highlight for the symbol
				if state.highlight_ns then
					-- Highlight the entire line with a subtle background
					vim.api.nvim_buf_add_highlight(
						state.original_buf,
						state.highlight_ns,
						"DocumentSymbolHighlight",
						symbol.line - 1, -- 0-indexed
						0,
						-1
					)

					-- Highlight the specific symbol range if available
					local start_col = symbol.range.start.character
					local end_col = symbol.range["end"] and symbol.range["end"].character or (start_col + #symbol.name)
					if end_col > start_col then
						vim.api.nvim_buf_add_highlight(
							state.original_buf,
							state.highlight_ns,
							"DocumentSymbolText",
							symbol.line - 1,
							start_col,
							end_col
						)
					end
				end
			else
				-- For Enter key, switch to the original window
				vim.api.nvim_set_current_win(original_win)
				vim.api.nvim_win_set_cursor(0, { symbol.line, symbol.range.start.character })
				vim.cmd("normal! zz") -- Center the line

				-- Clear highlights when navigating with Enter (since we're switching focus)
				if state.highlight_ns then
					vim.api.nvim_buf_clear_namespace(state.original_buf, state.highlight_ns, 0, -1)
				end
			end
		else
			-- Fallback if original window not found
			vim.api.nvim_set_current_buf(state.original_buf)
			vim.api.nvim_win_set_cursor(0, { symbol.line, symbol.range.start.character })
			if not preview_mode then
				vim.cmd("normal! zz")
			end
		end
	end
end

-- Live preview function for cursor movement
local function live_preview()
	jump_to_symbol(true)
end

-- Setup syntax highlighting
local function setup_syntax_highlighting()
	local buf = state.symbols_buf

	-- Define syntax groups
	vim.api.nvim_buf_call(buf, function()
		vim.cmd([[syntax clear]])

		-- Header line
		vim.cmd([[syntax match DocumentSymbolsHeader /^Document Symbols.*$/]])

		-- Symbol types in brackets
		vim.cmd([[syntax match DocumentSymbolsType /\[.*\]/]])

		-- Icons (first non-space character at line start)
		vim.cmd([[syntax match DocumentSymbolsIcon /^\s*\S/]])

		-- Line numbers in parentheses
		vim.cmd([[syntax match DocumentSymbolsLine /(line \d\+)$/]])

		-- Symbol names (everything between ] and ()
		vim.cmd([[syntax match DocumentSymbolsName /\] \zs[^(]\+\ze (/]])

		-- Set highlight groups
		vim.api.nvim_set_hl(0, "DocumentSymbolsHeader", { fg = "#61AFEF", bold = true })
		vim.api.nvim_set_hl(0, "DocumentSymbolsType", { fg = "#C678DD" })
		vim.api.nvim_set_hl(0, "DocumentSymbolsIcon", { fg = "#E5C07B" })
		vim.api.nvim_set_hl(0, "DocumentSymbolsLine", { fg = "#5C6370" })
		vim.api.nvim_set_hl(0, "DocumentSymbolsName", { fg = "#ABB2BF", bold = true })
	end)
end

-- Setup symbols buffer keymaps and commands
local function setup_symbols_buffer()
	local buf = state.symbols_buf

	-- Buffer options
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "documentsymbols")

	-- Keymaps
	vim.keymap.set("n", "<CR>", function() jump_to_symbol(false) end, { buffer = buf, silent = true })
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(state.symbols_win, false)
	end, { buffer = buf, silent = true })

	-- Set up live preview on cursor movement
	vim.api.nvim_create_autocmd({ "CursorMoved" }, {
		buffer = buf,
		callback = live_preview,
	})

	-- Filter command
	vim.api.nvim_buf_create_user_command(buf, "Filter", function(opts)
		local filter_type = opts.args ~= "" and opts.args or nil
		filter_symbols(filter_type)
	end, {
		nargs = "?",
		complete = function()
			return vim.tbl_values(symbol_kinds)
		end,
	})

	-- Clear filter command
	vim.api.nvim_buf_create_user_command(buf, "ClearFilter", function()
		filter_symbols(nil)
	end, {})

	-- Setup syntax highlighting
	setup_syntax_highlighting()
end

-- Main function to open document symbols
function M.open_document_symbols()
	-- Get current buffer
	state.original_buf = vim.api.nvim_get_current_buf()

	-- Create highlight namespace early
	state.highlight_ns = vim.api.nvim_create_namespace("DocumentSymbols")

	-- Set up highlight groups with nice colors
	vim.api.nvim_set_hl(0, "DocumentSymbolHighlight", { bg = "#3E4451", blend = 20 })            -- Subtle line highlight
	vim.api.nvim_set_hl(0, "DocumentSymbolText", { bg = "#61AFEF", fg = "#282C34", bold = true }) -- Symbol text highlight

	-- Request document symbols from LSP
	local params = {
		textDocument = vim.lsp.util.make_text_document_params(),
	}

	vim.lsp.buf_request(0, "textDocument/documentSymbol", params, function(err, result)
		if err then
			vim.notify("Error getting document symbols: " .. tostring(err), vim.log.levels.ERROR)
			return
		end

		if not result or vim.tbl_isempty(result) then
			vim.notify("No symbols found", vim.log.levels.INFO)
			return
		end

		-- Parse symbols
		state.all_symbols = parse_symbols(result)
		state.filtered_symbols = {}
		state.current_filter = nil

		-- Create new buffer for symbols
		state.symbols_buf = vim.api.nvim_create_buf(false, true)

		-- Open in a split
		vim.cmd("rightbelow vsplit")
		state.symbols_win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(state.symbols_win, state.symbols_buf)
		vim.api.nvim_win_set_width(state.symbols_win, 50)

		-- Setup buffer
		setup_symbols_buffer()
		update_symbols_buffer()

		-- Move cursor to first symbol (line 3)
		vim.api.nvim_win_set_cursor(state.symbols_win, { 3, 0 })

		-- Trigger initial preview to highlight the first symbol
		live_preview()
	end)
end

return M
