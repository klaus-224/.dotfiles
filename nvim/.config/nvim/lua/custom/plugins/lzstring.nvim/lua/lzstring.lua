local M = {}

local function make_scratch_buffer(label)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
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

local function run_decode(input_text)
	if vim.system then
		local result = vim.system({ "lzstring", "decode" }, { text = input_text }):wait()
		return result.code, result.stdout or "", result.stderr or ""
	end

	local stdout = vim.fn.system({ "lzstring", "decode" }, input_text)
	return vim.v.shell_error, stdout or "", ""
end

local function set_output_lines(buf, lines)
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
end

local function ensure_output_window(input_buf)
	local output_buf = vim.b[input_buf].lzstring_output_buf
	local output_win = vim.b[input_buf].lzstring_output_win

	if not output_buf or not vim.api.nvim_buf_is_valid(output_buf) then
		output_buf = make_scratch_buffer("decoded")
		vim.b[input_buf].lzstring_output_buf = output_buf
	end

	if not output_win or not vim.api.nvim_win_is_valid(output_win) then
		vim.cmd("rightbelow vsplit")
		output_win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(output_win, output_buf)
		vim.b[input_buf].lzstring_output_win = output_win
	end

	return output_buf, output_win
end

local function decode_from_input(input_buf)
	local encoded = table.concat(vim.api.nvim_buf_get_lines(input_buf, 0, -1, false), "\n")
	if vim.trim(encoded) == "" then
		vim.notify("LZStringDecode: input buffer is empty", vim.log.levels.WARN)
		return
	end

	local output_buf, output_win = ensure_output_window(input_buf)
	local code, stdout, stderr = run_decode(encoded)

	if code ~= 0 then
		local lines = { ("[lzstring decode failed: exit %d]"):format(code) }
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
	end

	if vim.api.nvim_win_is_valid(output_win) then
		vim.api.nvim_set_current_win(output_win)
	end
end

local function open_decode_workspace()
	vim.cmd("tabnew")
	local input_buf = make_scratch_buffer("input")
	local input_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(input_win, input_buf)

	vim.cmd("rightbelow vsplit")
	local output_win = vim.api.nvim_get_current_win()
	local output_buf = make_scratch_buffer("output")
	vim.api.nvim_win_set_buf(output_win, output_buf)
	set_output_lines(output_buf, {
		"Decoded output appears here.",
		"Run :LZDecodeRun from the input window or press <leader>dd.",
	})

	vim.b[input_buf].lzstring_output_buf = output_buf
	vim.b[input_buf].lzstring_output_win = output_win

	vim.api.nvim_buf_create_user_command(input_buf, "LZDecodeRun", function()
		decode_from_input(input_buf)
	end, { desc = "Decode the current LZString input buffer" })

	vim.keymap.set("n", "<leader>dd", function()
		decode_from_input(input_buf)
	end, { buffer = input_buf, silent = true, desc = "Decode LZString input" })

	vim.api.nvim_set_current_win(input_win)
	vim.notify("Paste encoded text, then run :LZDecodeRun (or <leader>dd)", vim.log.levels.INFO)
end

function M.setup()
	vim.api.nvim_create_user_command("LZStringDecode", function()
		open_decode_workspace()
	end, { desc = "Open a tab workspace for lzstring decode" })
end

return M
