let g:neomake_typescript_enabled_makers = ['eslint']

"autocmd FileType typescript setlocal makeprg=eslint\ --format\ compact

"autocmd FileType typescript set formatprg=eslint\ --format\ compact
autocmd FileType typescript set formatprg=prettier\ --parser\ typescript
autocmd BufWritePre *.ts silent call fns#Format()

"autocmd FileType go set formatprg=goimports
"autocmd BufWritePre *.go silent call fns#Format()
"nction! neoformat#formatters#typescript#prettier() abort
"return {
"\ 'exe': 'prettier',
"\ 'args': ['--stdin-filepath', '"%:p"', '--parser', 'typescript'],
"\ 'stdin': 1
"\ }
