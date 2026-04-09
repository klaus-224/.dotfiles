return {
	"norcalli/nvim-colorizer.lua",
	-- enabled = false, -- broken right now?
	config = function()
		require('colorizer').setup {
			'*'
		}
	end
}
