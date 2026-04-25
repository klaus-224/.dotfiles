local M = {}

local win_settings = {
  width = 60,
  height = 20,
  border = "rounded",
}

function M.setup(opts)
  opts = opts or {}

  win_settings = vim.tbl_deep_extend("force", win_settings, opts)
end

local state = {
  floating = {
    buf = -1,
    win = -1,
  },
}

local function create_floating_window(opts)
  opts = vim.tbl_deep_extend("force", win_settings, opts or {})

  vim.api.nvim_set_hl(0, "NormalFloat", { fg = "#5c6370" })

  local width = opts.width or 80
  local height = opts.height or 20

  local ui = vim.api.nvim_list_uis()[1]

  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)

  local buf = nil

  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = opts.border or "rounded",
  }

  local win = vim.api.nvim_open_win(buf, true, win_config)

  return {
    buf = buf,
    win = win,
  }
end

local toggle_terminal = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = create_floating_window({ buf = state.floating.buf })
    if vim.bo[state.floating.buf].buftype ~= "terminal" then
      vim.cmd.terminal()
    end
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end

vim.api.nvim_create_user_command("FloatingTerminal", toggle_terminal, {})
vim.keymap.set({ "n", "t" }, "<leader>tt", toggle_terminal)

return M
