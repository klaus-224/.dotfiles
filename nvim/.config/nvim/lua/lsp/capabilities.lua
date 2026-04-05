local M = {}

function M.get()
  if pcall(require, "blink.cmp") then
    return require("blink.cmp").get_lsp_capabilities()
  end

  return vim.lsp.protocol.make_client_capabilities()
end

return M
