if exists('current_compiler')
  finish
endif
let current_compiler = 'yamllint'

if exists(':CompilerSet') != 2  " older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=yamllint\ --format\ parsablemm
CompilerSet errorformat=%f:%l:%c:\ [%tarning]\ %m,%f:%l:%c:\ [%trror]\ %m,%-G%.%#
