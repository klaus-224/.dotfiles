local client_config = require("lsp.client-config")

local is_windows = vim.uv.os_uname().sysname:match("Windows") ~= nil
local venv_names = { ".venv", "venv", "env" }
local python_bin = is_windows and { "Scripts/python.exe", "python.exe" } or { "bin/python", "bin/python3" }
local project_root_markers = {
	"pyrightconfig.json",
	"pyproject.toml",
	"setup.py",
	"setup.cfg",
	"requirements.txt",
	"Pipfile",
	".git",
}
local package_root_markers = { "pyproject.toml", "setup.py", "setup.cfg" }

local function is_directory(path)
	return path and vim.fn.isdirectory(path) == 1
end

local function is_executable(path)
	return path and vim.fn.executable(path) == 1
end

local function normalize_dir(path)
	if not path or path == "" then
		return nil
	end

	if is_directory(path) then
		return vim.fs.normalize(path)
	end

	return vim.fs.normalize(vim.fs.dirname(path))
end

local function find_python_in_env(env_dir)
	if not is_directory(env_dir) then
		return nil
	end

	for _, suffix in ipairs(python_bin) do
		local candidate = vim.fs.joinpath(env_dir, suffix)
		if is_executable(candidate) then
			return candidate
		end
	end
end

local function path_exists(path)
	return path and vim.uv.fs_stat(path) ~= nil
end

local function has_file(dir, name)
	return path_exists(vim.fs.joinpath(dir, name))
end

local function has_venv(dir)
	for _, name in ipairs(venv_names) do
		if is_directory(vim.fs.joinpath(dir, name)) then
			return true
		end
	end

	return false
end

local function file_contains(path, needle)
	local file = io.open(path, "r")
	if not file then
		return false
	end

	local ok, content = pcall(file.read, file, "*a")
	file:close()
	return ok and type(content) == "string" and content:find(needle, 1, true) ~= nil
end

local function has_workspace_config(dir)
	return has_file(dir, "uv.lock")
		or file_contains(vim.fs.joinpath(dir, "pyproject.toml"), "[tool.uv.workspace]")
end

local function collect_search_dirs(...)
	local dirs = {}
	local seen = {}

	local function add_path(path)
		local dir = normalize_dir(path)
		if not dir then
			return
		end

		if not seen[dir] then
			seen[dir] = true
			dirs[#dirs + 1] = dir
		end

		for parent in vim.fs.parents(dir) do
			parent = vim.fs.normalize(parent)
			if not seen[parent] then
				seen[parent] = true
				dirs[#dirs + 1] = parent
			end
		end
	end

	for i = 1, select("#", ...) do
		add_path(select(i, ...))
	end

	return dirs
end

local function detect_root_dir(path)
	local project_root = vim.fs.root(path, project_root_markers)
	if not project_root then
		return normalize_dir(path)
	end

	for _, dir in ipairs(collect_search_dirs(path, project_root)) do
		if dir ~= project_root and has_venv(dir) and (has_file(dir, ".git") or has_workspace_config(dir)) then
			return dir
		end
	end

	return project_root
end

local function detect_python_path(bufname, root_dir)
	for _, dir in ipairs(collect_search_dirs(bufname, root_dir, vim.uv.cwd())) do
		for _, venv_name in ipairs(venv_names) do
			local python_path = find_python_in_env(vim.fs.joinpath(dir, venv_name))
			if python_path then
				return python_path
			end
		end
	end

	for _, env_var in ipairs({ "VIRTUAL_ENV", "CONDA_PREFIX" }) do
		local env_dir = vim.env[env_var]
		local python_path = find_python_in_env(env_dir)
		if python_path then
			return python_path
		end
	end

	for _, executable in ipairs({ "python3", "python" }) do
		local python_path = vim.fn.exepath(executable)
		if python_path ~= "" then
			return python_path
		end
	end
end

local function dedupe_paths(paths)
	local deduped = {}
	local seen = {}

	for _, path in ipairs(paths) do
		local normalized = vim.fs.normalize(path)
		if not seen[normalized] then
			seen[normalized] = true
			deduped[#deduped + 1] = normalized
		end
	end

	return deduped
end

local function apply_settings(client, updates)
	local settings = vim.tbl_deep_extend("force", client.config.settings or {}, updates)
	client.config.settings = settings
	client.settings = vim.deepcopy(settings)
	client:notify("workspace/didChangeConfiguration", { settings = settings })
end

local function apply_python_path(client, path)
	if not path or path == "" then
		return false
	end

	apply_settings(client, {
		python = {
			pythonPath = path,
		},
	})
	return true
end

local function detect_extra_paths(bufname, root_dir)
	local paths = {}

	local function add_src(dir)
		if not dir then
			return
		end

		local src = vim.fs.joinpath(dir, "src")
		if is_directory(src) then
			paths[#paths + 1] = src
		end
	end

	add_src(root_dir)
	add_src(vim.fs.root(bufname, package_root_markers))
	return dedupe_paths(paths)
end

local function apply_extra_paths(client, paths)
	if vim.tbl_isempty(paths) then
		return false
	end

	local analysis = ((client.config.settings or {}).basedpyright or {}).analysis or {}
	local merged_paths = dedupe_paths(vim.list_extend(vim.deepcopy(analysis.extraPaths or {}), paths))

	apply_settings(client, {
		basedpyright = {
			analysis = {
				extraPaths = merged_paths,
			},
		},
	})
	return true
end

local function set_python_path(command)
	local bufnr = vim.api.nvim_get_current_buf()
	local clients = vim.lsp.get_clients({
		bufnr = bufnr,
		name = "basedpyright",
	})

	if vim.tbl_isempty(clients) then
		vim.notify("No active basedpyright client for this buffer", vim.log.levels.WARN)
		return
	end

	for _, client in ipairs(clients) do
		local path = command.args ~= "" and command.args
			or detect_python_path(vim.api.nvim_buf_get_name(bufnr), client.config.root_dir)

		if not path then
			vim.notify("Unable to resolve a Python interpreter for basedpyright", vim.log.levels.WARN)
			return
		end

		apply_python_path(client, path)
	end
end

local function configure_workspace(client, bufnr)
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local path = detect_python_path(bufname, client.config.root_dir)
	local existing_python_path = ((client.config.settings or {}).python or {}).pythonPath

	if path and existing_python_path ~= path then
		apply_python_path(client, path)
	end

	apply_extra_paths(client, detect_extra_paths(bufname, client.config.root_dir))
end

vim.lsp.config("basedpyright", vim.tbl_deep_extend("force", client_config.base(), {
	cmd = { "basedpyright-langserver", "--stdio" },
	filetypes = { "python" },
	root_dir = function(bufnr, on_dir)
		on_dir(detect_root_dir(vim.api.nvim_buf_get_name(bufnr)))
	end,
	settings = {
		basedpyright = {
			analysis = {
				autoSearchPaths = true,
				diagnosticMode = "workspace",
				inlayHints = {
					genericTypes = true,
				},
			},
		},
	},
	before_init = function(_, config)
		local path = detect_python_path(config.root_dir, config.root_dir)
		local extra_paths = detect_extra_paths(config.root_dir, config.root_dir)

		config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
			basedpyright = {
				analysis = {
					extraPaths = extra_paths,
				},
			},
		})

		if path then
			config.settings = vim.tbl_deep_extend("force", config.settings, {
				python = {
					pythonPath = path,
				},
			})
		end
	end,
	on_attach = function(client, bufnr)
		configure_workspace(client, bufnr)

		vim.api.nvim_buf_create_user_command(bufnr, "LspPyrightOrganizeImports", function()
			local params = {
				command = "basedpyright.organizeimports",
				arguments = { vim.uri_from_bufnr(bufnr) },
			}
			client.request("workspace/executeCommand", params, nil, bufnr)
		end, {
			desc = "Organize Imports",
		})

		-- TODO: Probably don't need this
		vim.api.nvim_buf_create_user_command(bufnr, "LspPyrightSetPythonPath", set_python_path, {
			desc = "Reconfigure basedpyright with the provided python path, or auto-detect when omitted",
			nargs = "?",
			complete = "file",
		})
	end,
}))

vim.lsp.enable("basedpyright")
