local utils = require("core.utils")
local globals = require("core.globals")

globals.keymap.set("i", "jk", "<Esc>", utils.opts)
globals.keymap.set("v", "q", "<Esc>", utils.opts)
-- globals.keymap.set("n", "<leader>w", ":write<CR>", utils.opts_with_desc("Save buffer"))
-- globals.keymap.set("n", "<leader>q", ":quit<CR>", utils.opts_with_desc("Close current buffer"))
-- globals.keymap.set("n", "<leader>Q", ":qa!<CR>", utils.opts_with_desc("Force quit all buffers"))

-- select all
globals.keymap.set("n", "<C-a>", "gg<S-v>G", utils.opts_with_desc("Select all"))

-- move selected lines up/down and keep selection
globals.keymap.set("v", "J", ":m '>+1<CR>gv=gv", utils.opts_with_desc("Move selected lines down"))
globals.keymap.set("v", "K", ":m '<-2<CR>gv=gv", utils.opts_with_desc("Move selected lines up"))

-- diagnostics
globals.keymap.set("n", "<leader>e", vim.diagnostic.open_float, utils.opts_with_desc("Show line diagnostics"))
globals.keymap.set("n", "[e", vim.diagnostic.get_prev, utils.opts_with_desc("Previous diagnostic"))
globals.keymap.set("n", "]e", vim.diagnostic.get_next, utils.opts_with_desc("Next diagnostic"))

-- windows
globals.keymap.set("n", "<leader>=", [[<cmd>vertical resize +5<cr>]], utils.opts_with_desc("Increase window width"))
globals.keymap.set("n", "<leader>-", [[<cmd>vertical resize -5<cr>]], utils.opts_with_desc("Decrease window width"))
globals.keymap.set("n", "<leader>+", [[<cmd>horizontal resize +10<cr>]], utils.opts_with_desc("Increasewindow height"))

-- close all floating windows
globals.keymap.set("n", "<leader>W", utils.close_all_windows, utils.opts_with_desc("Close all floating windows"))

-- copy current buffer absolute file path to system clipboard
globals.keymap.set("n", "<leader>yp", utils.copy_cwd, utils.opts_with_desc("Copy full file path to clipboard"))

-- copy current selection to the system clipboad
globals.keymap.set(
	{ "v", "n" },
	"<leader>yY",
	utils.copy_to_clipboard,
	utils.opts_with_desc("Copy visual selection to clipboard")
)

-- bullets
globals.keymap.set("n", "<M-l>", "o- [ ] ", utils.opts_with_desc("Add TODO bullet in markdown"))

-- TODO move into custom functions
local function open_pr_file_diff(file, pr_number)
	local repo = vim.fn.systemlist("gh repo view --json nameWithOwner -q '.nameWithOwner'")[1]
	if vim.v.shell_error ~= 0 or not repo or repo == "" then
		vim.notify("Could not resolve GitHub repo", vim.log.levels.ERROR)
		return
	end

	local file_for_jq = file:gsub("\\", "\\\\"):gsub('"', '\\"')
	local jq = string.format('.[] | select(.filename=="%s") | (.patch // "(No textual patch)")', file_for_jq)
	local cmd = string.format(
		"gh api %s --paginate --jq %s",
		vim.fn.shellescape("repos/" .. repo .. "/pulls/" .. pr_number .. "/files"),
		vim.fn.shellescape(jq)
	)
	local diff_lines = vim.fn.systemlist(cmd)
	if vim.v.shell_error ~= 0 or #diff_lines == 0 then
		vim.notify("No diff found for: " .. file, vim.log.levels.WARN)
		return
	end

	local tmpfile = string.format("/tmp/pr-%s-%s.diff", pr_number, file:gsub("/", "__"))
	vim.fn.writefile(diff_lines, tmpfile)
	vim.cmd("edit " .. vim.fn.fnameescape(tmpfile))
	vim.bo.filetype = "diff"
end

vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*/.git/tmp/pr-*.md",
	callback = function(args)
		local pr_number = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":t"):match("pr%-(%d+)")
		if not pr_number then
			return
		end

		local items = {}
		for _, line in ipairs(vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)) do
			local file = line:match("^%- %[%`([^`]+)%`%]%(")
			if file then
				table.insert(items, { text = file })
			end
		end

		if #items == 0 then
			return
		end

		vim.fn.setloclist(0, {}, "r", { title = "PR Files #" .. pr_number, items = items })
		vim.cmd("lopen")
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "qf",
	callback = function(args)
		vim.cmd("wincmd L")
		local title = (vim.fn.getloclist(0, { title = 1 }).title or "")
		local pr_number = title:match("PR Files #(%d+)")
		if not pr_number then
			return
		end

		vim.keymap.set("n", "<CR>", function()
			local idx = vim.fn.line(".")
			local entry = vim.fn.getloclist(0)[idx]
			local file = entry and entry.text or ""
			if file == "" then
				return
			end
			vim.cmd("wincmd p")
			open_pr_file_diff(file, pr_number)
		end, { buffer = args.buf, silent = true, noremap = true, desc = "Open PR file diff" })
	end,
})
