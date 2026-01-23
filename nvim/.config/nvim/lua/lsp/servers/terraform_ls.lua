local globals = require("lsp.globals")

vim.lsp.config["terraformls"] = vim.tbl_deep_extend("force", globals.base(), {
	filetypes = { "terraform", "terraform-vars", "hcl" },
})

vim.lsp.enable("terraformls")
