local M = {}
local utils = require("custom.utils")

local COMMENT_TEMPLATE = {
  "# GH review comments",
  "",
  "## Entry",
  "- file: path/to/file.ext",
  "- line: 42",
  "- range: 42-45",
  "- comment: ",
  "",
}

local function repo_root()
  local root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
  if vim.v.shell_error ~= 0 or not root or root == "" then
    return nil
  end
  return root
end

local function collect_changed_files(lines)
  local files = {}
  local in_changed_files = false

  for _, line in ipairs(lines) do
    if line == "## Changed files" then
      in_changed_files = true
    elseif vim.startswith(line, "## ") and line ~= "## Changed files" then
      in_changed_files = false
    elseif in_changed_files and line ~= "" then
      table.insert(files, line)
    end
  end

  return files
end

local function open_diff(file)
  if not file or file == "" then
    return
  end

  vim.fn.system({ "git", "fetch", "origin", "main", "--quiet" })
  vim.cmd("tabnew")
  local head_buf = vim.api.nvim_get_current_buf()
  local head_lines = vim.fn.systemlist({ "git", "show", "HEAD:" .. file })
  if vim.v.shell_error ~= 0 then
    head_lines = { "" }
  end
  vim.bo[head_buf].buftype = "nofile"
  vim.bo[head_buf].bufhidden = "wipe"
  vim.bo[head_buf].swapfile = false
  vim.bo[head_buf].modifiable = true
  vim.api.nvim_buf_set_lines(head_buf, 0, -1, false, head_lines)
  vim.bo[head_buf].modifiable = false
  vim.bo[head_buf].filetype = vim.filetype.match({ filename = file }) or ""
  vim.api.nvim_buf_set_name(head_buf, "HEAD:" .. file)

  local head_win = vim.api.nvim_get_current_win()
  vim.cmd("leftabove vnew")
  local base_win = vim.api.nvim_get_current_win()
  local base_buf = vim.api.nvim_get_current_buf()
  local base_lines = vim.fn.systemlist({ "git", "show", "origin/main:" .. file })
  if vim.v.shell_error ~= 0 then
    base_lines = { "" }
  end

  vim.bo[base_buf].buftype = "nofile"
  vim.bo[base_buf].bufhidden = "wipe"
  vim.bo[base_buf].swapfile = false
  vim.bo[base_buf].modifiable = true
  vim.api.nvim_buf_set_lines(base_buf, 0, -1, false, base_lines)
  vim.bo[base_buf].modifiable = false
  vim.bo[base_buf].filetype = vim.filetype.match({ filename = file }) or ""
  vim.api.nvim_buf_set_name(base_buf, "origin/main:" .. file)
  vim.cmd("filetype detect")
  vim.api.nvim_set_current_win(base_win)
  vim.cmd("diffthis")

  vim.api.nvim_set_current_win(head_win)
  vim.cmd("diffthis")
end

function M.open_from_qf()
  local qf = vim.fn.getqflist({ items = 1 })
  local idx = vim.fn.line(".")
  local item = qf.items[idx]
  if not item then
    return
  end

  local file = item.filename ~= "" and item.filename or item.text
  open_diff(file)
end

function M.setup(pr_number)
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local files = collect_changed_files(lines)
  local file_set = {}
  local items = {}

  for _, file in ipairs(files) do
    file_set[file] = true
    table.insert(items, { filename = file, lnum = 1, col = 1, text = file })
  end

  vim.b.ghpr_pr_number = pr_number
  vim.b.ghpr_files = file_set
  vim.g.ghpr_pr_number = pr_number
  vim.g.ghpr_changed_files = files

  if #items > 0 then
    vim.fn.setqflist({}, "r", { title = "PR files", items = items })
    vim.cmd("copen")

    local qf_info = vim.fn.getqflist({ winid = 0 })
    if qf_info.winid and qf_info.winid ~= 0 then
      local qf_buf = vim.api.nvim_win_get_buf(qf_info.winid)
      vim.keymap.set("n", "<CR>", function()
        require("custom.git-pr").open_from_qf()
      end, { buffer = qf_buf, silent = true })
    end
  end

  vim.keymap.set("n", "<CR>", function()
    local file = vim.api.nvim_get_current_line()
    if not vim.b.ghpr_files[file] then
      vim.cmd("normal! <CR>")
      return
    end
    open_diff(file)
  end, { buffer = buf, silent = true })
end

local function comment_file_path(pr_number)
  local root = repo_root()
  if not root then
    return nil
  end
  if not pr_number or tostring(pr_number) == "" then
    return nil
  end
  local dir = root .. "/.git/tmp"
  vim.fn.mkdir(dir, "p")
  return dir .. "/pr-" .. tostring(pr_number) .. "-comments.md"
end

local function ensure_comment_file(path)
  if vim.fn.filereadable(path) == 0 or vim.fn.getfsize(path) == 0 then
    vim.fn.writefile(COMMENT_TEMPLATE, path)
  end
end

local function relative_file(path)
  if not path or path == "" then
    return ""
  end
  local root = repo_root()
  if not root then
    return path
  end
  if vim.startswith(path, root .. "/") then
    return string.sub(path, #root + 2)
  end
  return path
end

local function append_comment_entry(path, file, line, range)
  local entry = {
    "## Entry",
    "- file: " .. (file ~= "" and file or "path/to/file.ext"),
    "- line: " .. (line ~= "" and line or ""),
    "- range: " .. (range ~= "" and range or ""),
    "- comment: ",
    "",
  }
  vim.fn.writefile(entry, path, "a")
end

function M.open_comment(opts)
  opts = opts or {}
  local pr_number = opts.pr_number or vim.g.ghpr_pr_number or vim.env.GHPR_NUMBER
  local path = comment_file_path(pr_number)
  if not path then
    vim.notify("PRComment: missing PR number context", vim.log.levels.ERROR)
    return
  end

  ensure_comment_file(path)
  if opts.append ~= false then
    append_comment_entry(path, opts.file or "", opts.line or "", opts.range or "")
  end

  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)

  local win = utils.open_centered_float(buf, {
    width_ratio = 0.7,
    height_ratio = 0.7,
    border = "rounded",
    title = " PRComment ",
    title_pos = "center",
  })

  vim.bo[buf].modifiable = true
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.wo[win].wrap = true
  vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 11 })
end

function M.setup_commands()
  vim.api.nvim_create_user_command("PRComment", function(cmd)
    local args = vim.split(vim.trim(cmd.args or ""), "%s+", { plain = false, trimempty = true })
    local pr_number = vim.g.ghpr_pr_number or vim.env.GHPR_NUMBER
    if args[1] == "open" then
      if args[2] and args[2] ~= "" then
        pr_number = args[2]
      end
      require("custom.git-pr").open_comment({ append = false, pr_number = pr_number })
      return
    end
    local file = args[1] or relative_file(vim.api.nvim_buf_get_name(0))
    local line = args[2] or tostring(vim.api.nvim_win_get_cursor(0)[1])
    if args[3] and args[3] ~= "" then
      pr_number = args[3]
    end
    local range = ""
    if cmd.range == 2 and cmd.line1 ~= cmd.line2 then
      range = tostring(cmd.line1) .. "-" .. tostring(cmd.line2)
    end
    require("custom.git-pr").open_comment({ file = file, line = line, range = range, pr_number = pr_number })
  end, { nargs = "*", range = true })
end

return M
