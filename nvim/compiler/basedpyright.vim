if exists('current_compiler')
  finish
endif
let current_compiler = 'basedpyright'

CompilerSet makeprg=basedpyright\ --level\ error\ %

CompilerSet errorformat=%f:%l:%c\ -\ %t%*[^:]:\ %m
CompilerSet errorformat+=%-G%.%#
