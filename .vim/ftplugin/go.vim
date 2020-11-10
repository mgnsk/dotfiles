let s:formatter = 'goimports'

function! GoFormatToggle()
	if s:formatter == 'goimports'
		let s:formatter = 'gofmt'
	else
		let s:formatter = 'goimports'
	endif
endfunction

command GoFormatToggle :call GoFormatToggle()

autocmd BufWritePre *.go silent call fns#Format(s:formatter)
