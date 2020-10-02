autocmd BufWritePre *.proto silent call fns#Format('clang-format')
