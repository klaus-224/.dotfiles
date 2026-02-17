--- @sync entry

local function entry()
	local h = cx.active.current.hovered
	if not h then return end

	if h.cha.is_dir then
		ya.emit("cd", { tostring(h.url) })
	else
		ya.emit("shell", { "nvim -- %h", block = true })
	end
end

return { entry = entry }
