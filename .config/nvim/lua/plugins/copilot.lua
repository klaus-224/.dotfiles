-- Plugin Reference: https://github.com/CopilotC-Nvim/CopilotChat.nvim?tab=readme-ov-file
return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		enabled = vim.env.USER ~= "klaus224",
		dependencies = {
			{ "nvim-lua/plenary.nvim", branch = "master" },
		},
		build = "make tiktoken",
		config = function()
			-- window setup
			require("CopilotChat").setup({
				tools = "copilot",
				-- model = 'claude-sonnet-4.5',
				window = {
					layout = "float",
					width = 100, -- Fixed width in columns
					height = 45,
					border = "rounded", -- 'single', 'double', 'rounded', 'solid'
					zindex = 1,
				},
				headers = {
					user = "👤 Me",
					assistant = "🤖 Copilot",
					tool = "🔧 Tool",
				},

				separator = "━━",
				auto_fold = true, -- Automatically folds non-assistant messages

				mappings = {
					-- Add mapping here: https://github.com/CopilotC-Nvim/CopilotChat.nvim/blob/main/lua/CopilotChat/config/mappings.lua
					show_diff = "gq", -- default: gd
					show_info = "gi", -- default: gc
				},
			})

			local chat = require("CopilotChat")

			local sticky_prompt =
				"You are a software engineer who is terse, kind, but not talkative. Help your friend. You are very knowledgeable about coding, but would rather say that you don't know versus always providing a response."

			local original_ask = chat.ask
			chat.ask = function(prompt, ...)
				local new_prompt = sticky_prompt .. "\n" .. prompt
				return original_ask(new_prompt, ...)
			end

			-- keybinds
			vim.keymap.set("n", "<leader>co", chat.toggle, { desc = "Open CopilotChat" })
			vim.keymap.set("n", "<leader>ccr", "<cmd>CopilotChatReview<cr>", { desc = "Review Copilot changes" })
		end,
	},
}
