local M = {}

local function make_scratch_buffer(label, opts)
	opts = opts or {}
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = opts.buftype or "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = true
	vim.bo[buf].filetype = "text"
	vim.api.nvim_buf_set_name(buf, ("lzstring://%s/%d"):format(label, buf))
	return buf
end

local function to_lines(text)
	if not text or text == "" then
		return { "" }
	end
	return vim.split(text, "\n", { plain = true, trimempty = false })
end

local function set_output_lines(buf, lines)
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
end

local function format_input(raw_input)
	local trimmed = vim.trim(raw_input or "")
	if trimmed == "" then
		return ""
	end

	local ok, decoded = pcall(vim.json.decode, trimmed)
	if ok then
		if type(decoded) == "string" then
			return decoded
		end
		if type(decoded) == "table" then
			if type(decoded.json) == "string" then
				return decoded.json
			end
			for _, value in pairs(decoded) do
				if type(value) == "string" then
					return value
				end
			end
		end
	end

	local from_kv = trimmed:match(':%s*"([^"]+)"')
	if from_kv and from_kv ~= "" then
		return from_kv
	end

	local quoted = trimmed:match('^"(.*)"$')
	if quoted and quoted ~= "" then
		return quoted
	end

	return trimmed
end

local function run_decode_from_file(path)
	if vim.fn.exepath("lz-string") == "" then
		return 127, "", "lz-string CLI was not found in PATH"
	end

	if vim.system then
		local result = vim.system({ "lz-string", "-d", path }):wait()
		return result.code, result.stdout or "", result.stderr or ""
	end

	local output = vim.fn.system("lz-string -d " .. vim.fn.shellescape(path) .. " 2>&1")
	if vim.v.shell_error == 0 then
		return 0, output or "", ""
	end
	return vim.v.shell_error, "", output or ""
end

local function decode_from_input(input_buf)
	local output_buf = vim.b[input_buf].lzstring_output_buf
	if not output_buf or not vim.api.nvim_buf_is_valid(output_buf) then
		vim.notify("LZStringDecode: output buffer is unavailable", vim.log.levels.ERROR)
		return
	end

	local raw_input = table.concat(vim.api.nvim_buf_get_lines(input_buf, 0, -1, false), "\n")
	local formatted_input = format_input(raw_input)
	if formatted_input == "" then
		vim.notify("LZStringDecode: input buffer is empty", vim.log.levels.WARN)
		return
	end

	vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, to_lines(formatted_input))

	local path = vim.fn.tempname()
	local file, open_err = io.open(path, "w")
	if not file then
		set_output_lines(output_buf, {
			"[lz-string decode failed: could not create temp file]",
			open_err or "unknown error",
		})
		vim.notify("LZStringDecode: temp file creation failed", vim.log.levels.ERROR)
		return
	end
	file:write(formatted_input)
	file:close()

	local code, stdout, stderr = run_decode_from_file(path)
	vim.fn.delete(path)

	if code ~= 0 then
		local lines = { ("[lz-string decode failed: exit %d]"):format(code) }
		if stderr ~= "" then
			vim.list_extend(lines, { "", "[stderr]" })
			vim.list_extend(lines, to_lines(stderr))
		end
		if stdout ~= "" then
			vim.list_extend(lines, { "", "[stdout]" })
			vim.list_extend(lines, to_lines(stdout))
		end
		set_output_lines(output_buf, lines)
		vim.notify("LZStringDecode: decode failed", vim.log.levels.ERROR)
	else
		set_output_lines(output_buf, to_lines(stdout))
		vim.notify("LZStringDecode: decoded output updated", vim.log.levels.INFO)
	end

	vim.bo[input_buf].modified = false
end

local function attach_decode_on_write(input_buf)
	local group = vim.api.nvim_create_augroup("LZStringDecodeInput" .. input_buf, { clear = true })
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		group = group,
		buffer = input_buf,
		desc = "Decode input buffer using lz-string -d on write",
		callback = function(event)
			decode_from_input(event.buf)
		end,
	})
end

local function open_decode_workspace()
	vim.cmd("tabnew")

	local input_buf = make_scratch_buffer("input", { buftype = "acwrite" })
	local input_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(input_win, input_buf)
	vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, {
		"Paste encoded text in this buffer.",
		"Write the buffer (:w) to decode.",
	})

	vim.cmd("rightbelow vsplit")
	local output_win = vim.api.nvim_get_current_win()
	local output_buf = make_scratch_buffer("output")
	vim.api.nvim_win_set_buf(output_win, output_buf)
	set_output_lines(output_buf, {
		"Decoded output will appear here.",
		"Workspace initialized.",
	})

	vim.b[input_buf].lzstring_output_buf = output_buf
	vim.b[input_buf].lzstring_output_win = output_win

	attach_decode_on_write(input_buf)

	vim.api.nvim_set_current_win(input_win)
	vim.notify("LZString workspace created with fresh input/output buffers", vim.log.levels.INFO)
end

function M.setup(_)
	vim.api.nvim_create_user_command("LZStringDecode", function()
		open_decode_workspace()
	end, { desc = "Open a tab workspace with input and output buffers", force = true })
end

M.setup()
return M
