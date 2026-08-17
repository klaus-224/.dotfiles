local M = {}
-- cd to project root
function M.cd_project_root()
  local root = vim.fs.root(0, {
    '.git',
    'package.json',
    'pyproject.toml',
    'Cargo.toml',
    'Makefile',
  })

  if root then
    vim.cmd.cd(root)
    print('Changed directory to ' .. root)
  else
    vim.notify('Project root not found', vim.log.levels.WARN)
  end
end

return M
