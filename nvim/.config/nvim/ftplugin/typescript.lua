vim.cmd.compiler('tsc')

vim.api.nvim_create_user_command('Compile', function()
  vim.cmd('make')
end, {})
