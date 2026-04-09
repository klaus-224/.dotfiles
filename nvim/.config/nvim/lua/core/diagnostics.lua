local diag = vim.diagnostic
local sev = vim.diagnostic.severity

local function diagnostic_jump_callback(diagnostic, bufnr)
	if not diagnostic then
		return
	end

	diag.show(diagnostic.namespace, bufnr, { diagnostic }, {
		virtual_lines = { current_line = true },
		virtual_text = false,
		underline = true,
	})
end

diag.config({
	signs = false,
	underline = true,
	virtual_text = false, -- default OFF
	virtual_lines = false, -- default OFF except on jump callback
	severity_sort = true,
	float = {
		border = "rounded",
	},
	jump = {
		on_jump = diagnostic_jump_callback,
	},
})

-- Toggle virtual text
vim.keymap.set("n", "gK", function()
	local cfg = diag.config()
	local enabled = cfg.virtual_text

	if type(enabled) == "table" then
		enabled = true
	end

	diag.config({
		virtual_text = not enabled,
	})
end)

-- Populate loclist for current window/buffer, but do NOT open it.
-- Sort by severity first: ERROR -> WARN -> INFO -> HINT
local function set_diagnostic_loclist(opts)
	opts = opts or {}

	local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
	local winnr = opts.winnr or 0

	local diagnostics = diag.get(bufnr, { severity = { min = sev.WARN } })

	table.sort(diagnostics, function(a, b)
		if a.severity ~= b.severity then
			return a.severity < b.severity
		end
		if a.lnum ~= b.lnum then
			return a.lnum < b.lnum
		end
		return a.col < b.col
	end)

	local items = diag.toqflist(diagnostics)

	vim.fn.setloclist(winnr, {}, " ", {
		items = items,
	})
end

-- Populate loclist whenever diagnostics change, but never open it
vim.api.nvim_create_autocmd("DiagnosticChanged", {
	callback = function(args)
		if args.buf == vim.api.nvim_get_current_buf() then
			set_diagnostic_loclist({ bufnr = args.buf })
		end
	end,
})

-- Optional mapping to open the already-populated loclist
vim.keymap.set("n", "<leader>dl", function()
	set_diagnostic_loclist()
	vim.cmd("lopen")
end, { desc = "Open diagnostic loclist" })

-- ignore .env
local group = vim.api.nvim_create_augroup("__env", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = ".env*",
	group = group,
	callback = function(args)
		diag.enable(false, { bufnr = args.buf })
	end,
})
