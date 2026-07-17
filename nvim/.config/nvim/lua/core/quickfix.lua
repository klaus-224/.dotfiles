_G.QuickfixText = function(info)
  local items

  if info.quickfix == 1 then
    items = vim.fn.getqflist({
      id = info.id,
      items = 0,
    }).items
  else
    items = vim.fn.getloclist(info.winid, {
      id = info.id,
      items = 0,
    }).items
  end

  local lines = {}

  for i = info.start_idx, info.end_idx do
    local item = items[i]

    local path = item.bufnr > 0 and vim.fn.bufname(item.bufnr) or ''
    local filename = path ~= '' and vim.fn.fnamemodify(path, ':t') or '[No Name]'

    local position = ''
    if item.lnum > 0 then
      position = tostring(item.lnum)

      if item.col > 0 then
        position = position .. ':' .. item.col
      end
    end

    local message = (item.text or ''):gsub('\n', ' ')

    lines[#lines + 1] = string.format('%-24s %8s  %s', filename, position, message)
  end

  return lines
end

-- vim.o.quickfixtextfunc = 'v:lua.QuickfixText'
