let g:neomake_typescript_enabled_makers = ['eslint']

autocmd FileType typescript setlocal makeprg=eslint\ --format\ compact

autocmd BufWritePre *.ts lua vim.lsp.buf.formatting_sync(nil, 1000)
