return {
	"f-person/git-blame.nvim",
	event = "VeryLazy",
	config = function()
		require("gitblame").setup(
			{
				enabled = false,
				message_template = " <summary> • <date> • <author> • <<sha>>",
				date_format = "%r",
				virtual_text_column = 0,
				use_blame_commit_file_urls = false,
			}
		)
	end,
}
