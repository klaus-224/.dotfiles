return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "modern", -- or "classic", "helix"
		icons = {
			separator = "→",
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},
	config = function()
		local wk = require("which-key")

		wk.add({
			-- top level groups
			{ "<leader>c",  group = "Code" },
			{ "<leader>d",  group = "Debug" },
			{ "<leader>f",  group = "Find" },
			{ "<leader>g",  group = "Git" },
			{ "<leader>l",  group = "LSP" },
			{ "<leader>m",  group = "Marks" },
			{ "<leader>o",  group = "Open/Toggle" },
			{ "<leader>v",  group = "Rust" },
			{ "<leader>x",  group = "Diagnostics" },

			-- lsp operations
			{ "<leader>lf", desc = "Format buffer" },
			{ "<leader>ca", desc = "Code action" },

			-- find operations (Telescope)
			{ "<leader>ff", desc = "Find files" },
			{ "<leader>fg", desc = "Live grep" },
			{ "<leader>fb", desc = "Find buffers" },
			{ "<leader>fh", desc = "Find help tags" },
			{ "<leader>fw", desc = "Find word under cursor" },
			{ "<leader>fs", desc = "Find LSP symbols" },
			{ "<leader>fd", desc = "Find diagnostics" },
			{ "<leader>fB", desc = "Find git branches" },
			{ "<leader>fm", desc = "Find marks" },

			-- marks
			{ "<leader>m",  group = "Marks" },
			{ "<leader>mm", desc = "Toggle mark" },
			{ "[m",         desc = "Previous mark" },
			{ "]m",         desc = "Next mark" },

			-- code actions
			{ "<leader>cs", desc = "Symbols (Trouble)" },
			{ "<leader>cl", desc = "LSP definitions/references (Trouble)" },

			-- diagnostics (Trouble)
			{ "<leader>xx", desc = "Diagnostics (Trouble)" },
			{ "<leader>xX", desc = "Buffer diagnostics (Trouble)" },
			{ "<leader>xL", desc = "Location list (Trouble)" },
			{ "<leader>xQ", desc = "Quickfix list (Trouble)" },
			{ "<leader>e",  desc = "Show line diagnostics" },
			{ "[e",         desc = "Previous diagnostic" },
			{ "]e",         desc = "Next diagnostic" },

			{ "<leader>vE", desc = "Explain error" },
			{ "<leader>vC", desc = "Open Cargo.toml" },

			-- other non leader bindings
			{ "F",          desc = "Toggle Neo-tree" },
			{ "?",          desc = "Fuzzy find in buffer" },
			{ "J",          mode = "v",                                   desc = "Move selected lines down" },
			{ "K",          mode = "v",                                   desc = "Move selected lines up" },
			{ "K",          desc = "LSP hover" },
			{ "gD",         desc = "Go to declaration" },
			{ "gd",         desc = "Go to definition" },
			{ "gI",         desc = "Go to implementation" },
			{ "gr",         desc = "Go to references" },
			{ "gl",         desc = "Show line diagnostics" },
		})
	end,
}
