return {
	"norcalli/nvim-colorizer.lua",
	config = function()
		require('colorizer').setup {
			'*', -- Highlight all files, but customize some others.
		}
	end
}
