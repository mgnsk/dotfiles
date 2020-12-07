let g:clipboard = {
	\ 'name': 'myClipboard',
	\     'copy': {
	\         '+': {lines, regtype -> v:lua.osc52(join(lines, "\n"))},
	\     },
	\     'paste': {
	\         '+': '',
	\     },
	\ }

set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
set noexpandtab
set nocompatible
"set lazyredraw

" Show syn hi groups under cursor.
map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
	\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
	\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

" Use persistent history.
if !isdirectory($VIM_UNDO_DIR)
	call mkdir($VIM_UNDO_DIR)
endif
set undodir=$VIM_UNDO_DIR
set undofile

command LspStop lua vim.lsp.stop_client(vim.lsp.get_active_clients())

" use omni completion provided by lsp, seems to work by itself
autocmd Filetype * setlocal omnifunc=v:lua.vim.lsp.omnifunc
autocmd TermOpen term://* startinsert

"nnoremap <silent> gd    <cmd>lua vim.lsp.buf.declaration()<CR>
"nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
"nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>

" Customize fzf colors to match your color scheme
" - fzf#wrap translates this to a set of `--color` options
let g:fzf_colors =
	\ { 'fg':      ['fg', 'Normal'],
	\ 'bg':      ['bg', 'Normal'],
	\ 'hl':      ['fg', 'Comment'],
	\ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
	\ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
	\ 'hl+':     ['fg', 'Statement'],
	\ 'info':    ['fg', 'PreProc'],
	\ 'border':  ['fg', 'Ignore'],
	\ 'pointer': ['fg', 'Exception'],
	\ 'marker':  ['fg', 'Keyword'],
	\ 'spinner': ['fg', 'Label'],
	\ 'header':  ['fg', 'Comment'] }

" Rg uses ripgrep.
command! -bang -nargs=* Rg
	\ call fzf#vim#grep(
	\   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>), 1,
	\   fzf#vim#with_preview(), <bang>0)

command! -bang -nargs=? -complete=dir Files
	\ call fzf#vim#files(<q-args>, {'options': ['--layout=reverse', '--info=inline', '--preview', '~/.config/nvim/plugged/fzf.vim/bin/preview.sh {}']}, <bang>0)

command! -nargs=+ GotoOrOpen call fns#GotoOrOpen(<f-args>)

command! FZFMru call fzf#run({
	\ 'source':  reverse(s:all_files()),
	\ 'sink':    'edit',
	\ 'options': '-m -x +s',
	\ 'down':    '40%' })

function! s:all_files()
	return extend(
		\ filter(copy(v:oldfiles),
		\        "v:val !~ 'fugitive:\\|NERD_tree\\|^/tmp/\\|.git/'"),
		\ map(filter(range(1, bufnr('$')), 'buflisted(v:val)'), 'bufname(v:val)'))
endfunction
