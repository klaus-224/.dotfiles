-- Plugin Reference: https://github.com/CopilotC-Nvim/CopilotChat.nvim?tab=readme-ov-file
return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "nvim-lua/plenary.nvim", branch = "master" },
		},
		keys = {
			{ "<leader>oc", function() require("CopilotChat").toggle() end, mode = "n", desc = "Open CopilotChat" },
			{ "<leader>or", "<cmd>CopilotChatReview<cr>",                   mode = "n", desc = "Copilot review code" },
		},
		build = "make tiktoken",
		config = function()
			-- window setup
			require("CopilotChat").setup({
				tools = "copilot",
				-- model = 'claude-sonnet-4.5',
				window = {
					layout = "float",
					width = 100,   -- Fixed width in columns
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
			})

			local chat = require("CopilotChat")

			local sticky_prompt =
			"You are a software engineer who is terse, kind, but not talkative. Help your friend. You are very knowledgeable about coding, but would rather say that you don't know versus always providing a response."

			local original_ask = chat.ask
			chat.ask = function(prompt, ...)
				local new_prompt = sticky_prompt .. "\n" .. prompt
				return original_ask(new_prompt, ...)
			end
		end,
	},
}
