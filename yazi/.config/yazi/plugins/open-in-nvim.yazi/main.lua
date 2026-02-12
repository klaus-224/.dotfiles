--- @sync entry

local function entry()
	local h = cx.active.current.hovered
	if not h then return end

	if h.cha.is_dir then
		ya.emit("cd", { tostring(h.url) })
		ya.emit("shell", { "nvim .", block = true })
	else
		ya.emit("open", { hovered = true })
	end
end

return { entry = entry }
