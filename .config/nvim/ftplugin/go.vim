autocmd FileType go set formatprg=goimports
autocmd BufWritePre *.go silent call fns#Format()
