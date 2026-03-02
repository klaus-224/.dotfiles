---@module "lazy"
---@type LazySpec
return {
	"github/copilot.vim",
	enabled = function()
		local user = os.getenv("USER")
		return user ~= "klaus224"
	end,
}
