let s:formatter = 'goimports'

let s:current = 0

let s:formatters = ['gofmt', 'goimports', 'gofumpt', 'gofumports']

let g:neoformat_enabled_go = ['goimports']

function! GoFormatToggle()
	let s:current += 1

	let selected = s:formatters[s:current%len(s:formatters)]

	let g:neoformat_enabled_go = [selected]
	echo 'Go formatter set to ' . selected
endfunction

command GoFormatToggle :call GoFormatToggle()

autocmd BufWritePre *.go silent call fns#Format()
