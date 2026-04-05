local M = {}

function M.base()
  return {
    capabilities = require("lsp.capabilities").get(),
  }
end

return M
