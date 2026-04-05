local M = {}

function M.setup()
  require("lsp.on-attach").setup()
  require("lsp.enable").setup()
end

return M
