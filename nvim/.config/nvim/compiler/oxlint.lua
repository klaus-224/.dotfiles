-- compiler/oxlint.lua

if vim.b.current_compiler then
  return
end

vim.b.current_compiler = "oxlint"

vim.opt_local.makeprg = "pnpm oxlint --format=unix"

vim.opt_local.errorformat = {
  "%f:%l:%c: %m [%t%*[^/]/%*[^]]]",
  "%-G%.%#",
}
