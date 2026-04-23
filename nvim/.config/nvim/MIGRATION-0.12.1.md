# file structure
```
keymaps.lua -> all keymaps
options.lua -> options
init.lua -> add plugins, do the loading start, load keymaps and options, use
nvim-lspconfig instead of manually adding capabilities, calls lsp.enable()
plugins/
    <ALL PLUGINS>
```

# Loading Strat:
*During Startup*
```
vim.pack.add({'git url'})
```
*Not during startup but not lazy*
```
vim.schedule(function()
  vim.pack.add({
  })
```

*On Events*
```
vim.api.nvim_create_autocmd('CmdlineEnter', { once = true, callback = function()
  vim.pack.add({ 'https://github.com/nvim-mini/mini.cmdline' })
  require('mini.cmdline').setup()
end })

vim.api.nvim_create_autocmd('InsertEnter', { once = true, callback = function()
  vim.pack.add({ 'https://github.com/nvim-mini/mini.completion' })
  require('mini.completion').setup()
end })
```


# Plugins
TODO: classify start up, after startup, on event?

```
alpha.lua
autopairs.lua
blame.lua
blink.lua
colorizer.lua
colorscheme.lua
comments.lua
copilot.lua
customplugins.lua
dadbod.lua
flash.lua
formatting.lua
lint.lua
lsp.lua
markdown.lua
oil.lua
rust.lua
statusline.lua
surround.lua
telescope.lua
tmux.lua
treesitter.lua
```

