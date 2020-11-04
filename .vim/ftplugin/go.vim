autocmd BufWritePre *.go silent call fns#Format('goimports')
