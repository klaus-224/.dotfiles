-- Meant to run at async context. (yazi system-clipboard)

local get_hovered_path = ya.sync(function()
	local hovered = cx.active.current.hovered
	if not hovered then return nil end
	return tostring(hovered.url)
end)

local get_dirname = ya.sync(function()
	local hovered = cx.active.current.hovered
	if not hovered then return nil end
	return tostring(hovered.url:parent())
end)

local get_filename = ya.sync(function()
	local hovered = cx.active.current.hovered
	if not hovered then return nil end
	return hovered.name
end)

local get_stem = ya.sync(function()
	local hovered = cx.active.current.hovered
	if not hovered then return nil end
	return hovered.stem or hovered.name
end)

local function copy_text(text)
	local cmd
	if ya.target_os() == "macos" then
		cmd = Command("pbcopy"):stdin(Command.PIPED)
	elseif os.getenv("WAYLAND_DISPLAY") then
		cmd = Command("wl-copy"):stdin(Command.PIPED)
	else
		cmd = Command("xclip"):args({ "-selection", "clipboard" }):stdin(Command.PIPED)
	end

	local child, err = cmd:spawn()
	if not child then
		return false, string.format("Failed to spawn clipboard command: %s", tostring(err))
	end

	child:write_all(text)
	child:flush()

	local status = child:wait()
	return status and status.success, nil
end

local function copy_file(url)
	if ya.target_os() == "macos" then
		local status = Command("osascript")
			:arg("-e"):arg("on run args")
			:arg("-e"):arg("set the clipboard to POSIX file (first item of args)")
			:arg("-e"):arg("end")
			:arg(url)
			:spawn():wait()
		return status and status.success, nil
	else
		-- Linux: use x-special/gnome-copied-files for file manager paste
		local data = "copy\nfile://" .. url
		local cmd
		if os.getenv("WAYLAND_DISPLAY") then
			cmd = Command("wl-copy"):arg("--type"):arg("x-special/gnome-copied-files"):stdin(Command.PIPED)
		else
			cmd = Command("xclip"):args({ "-selection", "clipboard", "-t", "x-special/gnome-copied-files" }):stdin(Command.PIPED)
		end

		local child, err = cmd:spawn()
		if not child then
			return false, string.format("Failed to spawn clipboard command: %s", tostring(err))
		end

		child:write_all(data)
		child:flush()

		local status = child:wait()
		return status and status.success, nil
	end
end

return {
	entry = function(_, job)
		local mode = job.args[1] or "path"

		if mode == "file" then
			ya.emit("escape", { visual = true })
			local url = get_hovered_path()
			if not url then
				return ya.notify({ title = "System Clipboard", content = "No file selected", level = "warn", timeout = 5 })
			end

			local ok, err = copy_file(url)
			if ok then
				ya.notify({ title = "System Clipboard", content = "Copied file to clipboard", level = "info", timeout = 5 })
			else
				ya.notify({ title = "System Clipboard", content = err or "Failed to copy file", level = "error", timeout = 5 })
			end
		else
			local getters = {
				path = get_hovered_path,
				dirname = get_dirname,
				filename = get_filename,
				name_without_ext = get_stem,
			}

			local getter = getters[mode]
			if not getter then
				return ya.notify({ title = "System Clipboard", content = string.format("Unknown mode: %s", mode), level = "error", timeout = 5 })
			end

			local text = getter()
			if not text then
				return ya.notify({ title = "System Clipboard", content = "No file hovered", level = "warn", timeout = 5 })
			end

			local ok, err = copy_text(text)
			if ok then
				ya.notify({ title = "System Clipboard", content = string.format("Copied %s: %s", mode, text), level = "info", timeout = 5 })
			else
				ya.notify({ title = "System Clipboard", content = err or "Failed to copy", level = "error", timeout = 5 })
			end
		end
	end,
}
