-- START HELPERS --
local keymap = vim.keymap
local opts = { noremap = true, silent = true }
-- Adds a description to the keymap
local function opts_with_desc(desc)
	return vim.tbl_extend('force', opts, { desc = desc })
end
-- END HELPERS --

-- START GENERAL --
keymap.set('i', 'jk', '<Esc>', opts)
keymap.set('v', 'q', '<Esc>', opts)
keymap.set('n', '<leader>s', ':write<Return>', opts_with_desc('Save buffer'))
keymap.set('n', '<leader>w', ':quit<Return>', opts_with_desc('Close current buffer'))
keymap.set('n', '<leader>Q', ':qa<Return>', opts_with_desc('Force quit all buffers'))
-- Select All
keymap.set('n', '<C-a>', 'gg<S-v>G', opts_with_desc('Select all'))
-- Formatting
keymap.set('n', '<leader>gf', vim.lsp.buf.format, opts_with_desc('Format buffer'))
-- END GENERAL --


--START WINDOWS --
-- Move windows
keymap.set('n', '<leader>h', '<C-w>h', opts)
keymap.set('n', '<leader>k', '<C-w>k', opts)
keymap.set('n', '<leader>j', '<C-w>j', opts)
keymap.set('n', '<leader>l', '<C-w>l', opts)
-- Split window
keymap.set('n', '<leader>sv', ':vsplit<Return>', opts_with_desc('Split buffer vertically'))
keymap.set('n', '<leader>sh', ':split<Return>', opts_with_desc('Split buffer horizontally'))
-- Resize windows
keymap.set('n', '<leader>=', [[<cmd>vertical resize +5<cr>]])
keymap.set('n', '<leader>-', [[<cmd>vertical resize -5<cr>]])
keymap.set('n', '<leader>+', [[<cmd>horizontal resize +10<cr>]])
keymap.set('n', '<leader>_', [[<cmd>horizontal resize -10<cr>]])
-- END WINDOWS --


-- START CUSTOM FUNCTIONS --
-- Close all floating windows
keymap.set(
	'n',
	'<leader>W',
	function()
		local closed_windows = {}
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local config = vim.api.nvim_win_get_config(win)
			if config.relative ~= '' then    -- is_floating_window?
				vim.api.nvim_win_close(win, false) -- do not force
				table.insert(closed_windows, win)
			end
		end
		print(string.format('Closed %d windows: %s', #closed_windows, vim.inspect(closed_windows)))
	end,
	opts_with_desc('Close all floating windows')
)
-- Copy current buffer absolute file path to system clipboard
keymap.set(
	'n',
	'<leader>yp',
	function()
		vim.fn.setreg('+', vim.fn.expand('%:p'))
		vim.notify('Copied file path to clipboard')
	end,
	opts_with_desc('Copy full file path to clipboard')
)
-- Copy current selection to the system clipboad
keymap.set(
	{ 'v', 'n' },
	'<leader>Y',
	function()
		vim.cmd('normal! "+y')
		vim.notify("Copied selection to clipboard")
	end,
	opts_with_desc('Copy visual selection to clipboard')
)
-- END CUSTOM FUNCTIONS --
