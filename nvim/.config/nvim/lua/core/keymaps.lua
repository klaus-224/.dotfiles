local utils = require("core.utils")
local globals = require("core.globals")

globals.keymap.set("i", "jk", "<Esc>", utils.opts)
globals.keymap.set("v", "q", "<Esc>", utils.opts)
-- globals.keymap.set("n", "<leader>w", ":write<CR>", utils.opts_with_desc("Save buffer"))
-- globals.keymap.set("n", "<leader>q", ":quit<CR>", utils.opts_with_desc("Close current buffer"))
-- globals.keymap.set("n", "<leader>Q", ":qa!<CR>", utils.opts_with_desc("Force quit all buffers"))

-- select all
globals.keymap.set("n", "<C-a>", "gg<S-v>G", utils.opts_with_desc("Select all"))

-- qf list
globals.keymap.set("n", "D-j", ":cnext", {});
globals.keymap.set("n", "D-k", ":cprev", {});

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
