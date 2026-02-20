-- Reload custom lua files
function ReloadCustomLuaFiles()
	local config_dir = vim.fn.stdpath("config") .. "/lua/custom/"
	local files = {
		"auto-cmds.lua",
		"custom-functions.lua",
	}
	for _, file in ipairs(files) do
		vim.cmd("luafile " .. config_dir .. file)
	end
	print("Custom config reloaded.")
end

-- User command to Reload lua
vim.api.nvim_create_user_command("ReloadLua", "lua ReloadCustomLuaFiles()", {})
