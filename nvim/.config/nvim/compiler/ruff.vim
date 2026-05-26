" usage:
" -- for errors:
" :compiler ruff
" :make .
" -- for fixes:
" :compiler ruff
" :make --fix .
" -- single file:
" :make --fix %

if exists('current_compiler')
  finish
endif
let current_compiler = 'ruff'

CompilerSet makeprg=ruff\ check\ --output-format=concise\ $*
CompilerSet errorformat=%f:%l:%c:\ %m,%f:%l:\ %m,%f:%l:%c\ -\ %m,%f:
CompilerSet errorformat+=%-GFound\ %.%#
