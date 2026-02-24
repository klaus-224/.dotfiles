local M = {}

function M.open_centered_float(buf, opts)
  opts = opts or {}
  local width = math.floor(vim.o.columns * (opts.width_ratio or 0.7))
  local height = math.floor(vim.o.lines * (opts.height_ratio or 0.7))
  local row = math.floor((vim.o.lines - height) / 2) - 1
  local col = math.floor((vim.o.columns - width) / 2)

  return vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(row, 0),
    col = math.max(col, 0),
    style = "minimal",
    border = opts.border or "rounded",
    title = opts.title,
    title_pos = opts.title_pos or "center",
  })
end

return M
