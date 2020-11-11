let s:formatter = 'goimports'

function! GoFormatToggle()
	if s:formatter == 'goimports'
		let s:formatter = 'gofmt'
	else
		let s:formatter = 'goimports'
	endif
	let g:neoformat_enabled_go = [s:formatter]
	echo 'Go formatter set to ' . s:formatter
endfunction

command GoFormatToggle :call GoFormatToggle()

autocmd BufWritePre *.go silent Neoformat
