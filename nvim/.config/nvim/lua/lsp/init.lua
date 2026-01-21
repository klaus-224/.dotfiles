local servers = {
	"lua_ls",
	"yaml_ls",
	"docker_ls",
	"terraform_ls",
	"bash_ls",
	"pyright_ls",
	"ts_ls",
	"prisma_ls",
	"svelte_ls",
	"html_ls",
	"css_ls",
	"tailwindcss_ls",
	"json_ls",
}

for _, server in ipairs(servers) do
	require("lsp.servers." .. server)
end
