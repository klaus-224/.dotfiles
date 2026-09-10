if exists("current_compiler")
  finish
endif

let current_compiler = "zsh"

CompilerSet makeprg=zsh\ -n\ %:S
CompilerSet errorformat=%f:%l:\ %m
