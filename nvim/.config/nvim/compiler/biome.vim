" Vim compiler file
" Compiler:     Biome (= linter for JavaScript, TypeScript, JSX, TSX, JSON,
"               JSONC, HTML, Vue, Svelte, Astro, CSS, GraphQL and GritQL files)
" Maintainer:   @Konfekt
" Last Change:  2025 Nov 12
if exists("current_compiler") | finish | endif
let current_compiler = "biome"

let s:cpo_save = &cpo
set cpo&vim

exe 'CompilerSet makeprg=' .. escape(
      \ 'biome lint --reporter=concise '
      \ .. get(b:, 'biome_makeprg_params',
      \        get(g:, 'biome_makeprg_params', '')),
      \ ' \|"')

CompilerSet errorformat=%E×\ %f:%l:%c:\ %m
CompilerSet errorformat+=%W!\ %f:%l:%c:\ %m
CompilerSet errorformat+=%Ii\ %f:%l:%c:\ %m
CompilerSet errorformat+=%-G%.%#

let &cpo = s:cpo_save
