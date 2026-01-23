local client_config = require("lsp.client-config")

vim.lsp.config["terraformls"] = vim.tbl_deep_extend("force", client_config.base(), {
	filetypes = { "terraform", "terraform-vars", "hcl" },
})

vim.lsp.enable("terraformls")
