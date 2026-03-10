return {
	"goolord/alpha-nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local alpha = require("alpha")

		local quote = {
			'"I can do nothing for you but work on myself...',
			'         you can do nothing for me but work on yourself"',
		}

		local author = { "                              — Ram Dass - Darci Miller"}

		local function center_padding()
			local height = vim.fn.winheight(0)
			local content_height = #quote + #author
			return math.floor((height - content_height) / 2) - 1
		end

		vim.api.nvim_set_hl(0, "AlphaRegular", { fg="#e8b589", italic = true })
		vim.api.nvim_set_hl(0, "AlphaItalic", { fg="#c48282", italic = true })
		vim.api.nvim_set_hl(0, "AlphaAuthor", { fg="#6e94b2", italic = true })

		alpha.setup({
			layout = {
				{ type = "padding", val = center_padding() },

				{
					type = "text",
					val = { quote[1] },
					opts = {
						position = "center",
						hl = "AlphaRegular",
					},
				},

				{
					type = "text",
					val = { quote[2] },
					opts = {
						position = "center",
						hl = "AlphaItalic",
					},
				},

				{ type = "padding", val = 1 },

				{
					type = "text",
					val = author,
					opts = {
						position = "center",
						hl = "AlphaAuthor",
					},
				},
				{ type = "padding", val = center_padding() },
			},

		})
	end,
}
