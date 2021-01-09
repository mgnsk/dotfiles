let g:clipboard = {
	\ 'name': 'myClipboard',
	\     'copy': {
	\         '+': {lines, regtype -> v:lua.osc52(join(lines, "\n"))},
	\     },
	\     'paste': {
	\         '+': '',
	\     },
	\ }

" Show syn hi groups under cursor.
map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
	\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
	\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

command LspStop lua vim.lsp.stop_client(vim.lsp.get_active_clients())

autocmd Filetype * setlocal omnifunc=v:lua.vim.lsp.omnifunc
autocmd TermOpen term://* startinsert

function! RipgrepFzf(query, fullscreen)
	let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
	let initial_command = printf(command_fmt, shellescape(a:query))
	let reload_command = printf(command_fmt, '{q}')
	let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
	call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

command! -nargs=+ GotoOrOpen call fns#GotoOrOpen(<f-args>)
