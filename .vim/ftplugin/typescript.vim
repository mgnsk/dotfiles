let g:neomake_typescript_enabled_makers = ['eslint']

autocmd FileType typescript setlocal makeprg=eslint\ --format\ compact
