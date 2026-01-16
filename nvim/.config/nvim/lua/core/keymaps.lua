local utils = require('core.utils')
local globals = require('core.globals')

globals.keymap.set('i', 'jk', '<Esc>', utils.opts)
globals.keymap.set('v', 'q', '<Esc>', utils.opts)
globals.keymap.set('n', '<leader>w', ':write<Return>', utils.opts_with_desc('Save buffer'))
globals.keymap.set('n', '<leader>q', ':quit<Return>', utils.opts_with_desc('Close current buffer'))
globals.keymap.set('n', '<leader>Q', ':qa!<Return>', utils.opts_with_desc('Force quit all buffers'))
-- select all
globals.keymap.set('n', '<C-a>', 'gg<S-v>G', utils.opts_with_desc('Select all'))
-- formatting
globals.keymap.set('n', '<leader>lf', vim.lsp.buf.format, utils.opts_with_desc('Format buffer'))

-- windows
globals.keymap.set('n', '<leader>sv', ':vsplit<Return>', utils.opts_with_desc('Split buffer vertically'))
globals.keymap.set('n', '<leader>sh', ':split<Return>', utils.opts_with_desc('Split buffer horizontally'))
globals.keymap.set('n', '<leader>=', [[<cmd>vertical resize +5<cr>]], utils.opts_with_desc('Increase window width'))
globals.keymap.set('n', '<leader>-', [[<cmd>vertical resize -5<cr>]], utils.opts_with_desc('Decrease window width'))
globals.keymap.set('n', '<leader>+', [[<cmd>horizontal resize +10<cr>]], utils.opts_with_desc('Increasewindow height'))

-- close all floating windows
globals.keymap.set(
	'n',
	'<leader>W',
	utils.close_all_windows,
	utils.opts_with_desc('Close all floating windows')
)
-- copy current buffer absolute file path to system clipboard
globals.keymap.set(
	'n',
	'<leader>yp',
	utils.copy_cwd,
	utils.opts_with_desc('Copy full file path to clipboard')
)
-- copy current selection to the system clipboad
globals.keymap.set(
	{ 'v', 'n' },
	'<leader>yY',
	utils.copy_to_clipboard,
	utils.opts_with_desc('Copy visual selection to clipboard')
)
