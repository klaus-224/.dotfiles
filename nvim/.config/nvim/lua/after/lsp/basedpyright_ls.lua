local client_config = require("lsp.client-config")

return vim.tbl_deep_extend("force", client_config.base(), {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "pyrightconfig.json",
    "ruff.toml",
    ".ruff.toml",
    ".git",
  },
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "standard",
        diagnosticMode = "openFilesOnly",
        useLibraryCodeForTypes = true,
      },
    },
    pyright = {
      disableOrganizeImports = true,
    },
  },
})
