autocmd BufWritePre *.rs silent call fns#Format('rustfmt')
