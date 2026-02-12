-- DuckDB plugin configuration
require("duckdb"):setup({
	-- mode = "standard" / "summarized", -- Default: "summarized"
	-- cache_size = 1000,                -- Default: 500
	-- row_id = true / false / "dynamic", -- Default: false
})
