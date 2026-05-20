-- local function filename()
--   local name = vim.fn.expand('%:h')
--
--   if name == '' then
--     name = ''
--   end
--
--   local modified = vim.bo.modified and ' [+]' or ''
--   local readonly = vim.bo.readonly and ' [RO]' or ''
--
--   return ' ' .. name .. modified .. readonly .. ' '
-- end

local function buffers()
  local current = vim.api.nvim_get_current_buf()
  local all = {}

  -- all buffers that are loaded
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
      table.insert(all, bufnr)
    end
  end

  local limit = 4

  if #all > limit then
    local current_index = 1

    for i, bufnr in ipairs(all) do
      if bufnr == current then
        current_index = i
        break
      end
    end

    local start = math.max(1, current_index - math.floor(limit / 2))
    local finish = math.min(#all, start + limit - 1)

    if finish - start + 1 < limit then
      start = math.max(1, finish - limit + 1)
    end

    local visible = {}

    for i = start, finish do
      table.insert(visible, all[i])
    end

    all = visible
  end

  local parts = {}

  for _, bufnr in ipairs(all) do
    local name = vim.api.nvim_buf_get_name(bufnr)

    if name == '' then
      return
    else
      name = vim.fn.fnamemodify(name, ':t')
    end

    local hl = bufnr == current and '%#StatusLineBufferActive#' or '%#StatusLineBuffer#'

    table.insert(parts, hl .. ' ' .. name .. ' ')
  end

  return table.concat(parts, '%#StatusLine#')
end
