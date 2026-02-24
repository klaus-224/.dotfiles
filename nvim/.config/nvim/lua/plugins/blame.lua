return {
	"f-person/git-blame.nvim",
	event = "VeryLazy",
	opts = {
		enabled = true,
		message_template = " <summary> • <date> • <author> • <<sha>>",
		date_format = "%r",
		virtual_text_column = 1,
	},
	config = function()
		vim.g.gitblame_use_blame_commit_file_urls = true
	end,
}
