return {
	"epwalsh/obsidian.nvim",
	event = "VeryLazy",
	version = "*", -- recommended, use latest release instead of latest commit
	ft = "markdown",
	-- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
	-- event = {
	--   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
	--   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
	--   "BufReadPre path/to/my-vault/**.md",
	--   "BufNewFile path/to/my-vault/**.md",
	-- },
	dependencies = {
		-- Required.
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "notes",
				path = "~/Documents/notes",
			},
		},
		completion = {
			-- Set to false to disable completion.
			nvim_cmp = true,
			-- Trigger completion at 2 chars.
			min_chars = 2,
		},
		note_id_func = function(title)
			local suffix = ""
			if title ~= nil then
				-- If title is given, transform it into valid file name.
				suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
			else
				-- If title is nil, just add 4 random uppercase letters to the suffix.
				for _ = 1, 4 do
					suffix = tostring(os.time()) .. "-" .. string.char(math.random(65, 90))
				end
			end
			return suffix
		end,
		disable_frontmatter = true,
		follow_url_func = function(url)
			vim.fn.jobstart({ "open", url }) -- Mac OS
		end,
	},
	sort_by = "modified",
	sort_reversed = true,
}
