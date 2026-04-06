local client_config = require("lsp.client-config")

return vim.tbl_deep_extend("force", client_config.base(), {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "ruff.toml",
    ".ruff.toml",
    ".git",
  },
  init_options = {
    settings = {
      logLevel = "error",
    },
  },
})
