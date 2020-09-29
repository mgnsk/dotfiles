source ~/.vim/plugins.vim

set runtimepath+=~/.fzf

let g:neomake_open_list = 2

" COC autostart.
let g:coc_start_at_startup = 0

" the configuration options should be placed before `colorscheme sonokai`
let g:sonokai_style = 'atlantis'
let g:sonokai_enable_italic = 0
let g:sonokai_disable_italic_comment = 0

let g:rainbow_active = 1
let g:rainbow_guifgs = [
			\ '#458588',
			\ '#d19a66',
			\ '#2D72AB',
			\ '#d65d0e',
			\ '#458588',
			\ '#b16286',
			\ '#78cee9',
			\ '#d65d0e',
			\ '#458588',
			\ '#b16286',
			\ '#98c379',
			\ '#d65d0e',
			\ '#458588',
			\ '#b16286',
			\ '#ff6d7e',
			\ '#d65d0e',
			\ ]

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
			\ 'prompt':  ['fg', 'Conditional'],
			\ 'pointer': ['fg', 'Exception'],
			\ 'marker':  ['fg', 'Keyword'],
			\ 'spinner': ['fg', 'Label'],
			\ 'header':  ['fg', 'Comment'] }


set lazyredraw

set termguicolors
colorscheme sonokai
set t_ut=

" Show syn hi groups under cursor.
map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
			\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
			\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>




let mapleader = ','

" govim
"set completeopt+=popup

"set completepopup=align:menu,border:off,highlight:Pmenu

set nofoldenable

"B
"au InsertEnter * silent execute "!echo -en \<esc>[5 q"
"au InsertLeave * silent execute "!echo -en \<esc>[2 q" 
"set guicursor=


" TextEdit might fail if hidden is not set.
set hidden

set nobackup
"set nocompatible

" Safety settings.
set writebackup
set swapfile

" Use persistent history.
if !isdirectory($VIM_UNDO_DIR)
	call mkdir($VIM_UNDO_DIR)
endif
set undodir=$VIM_UNDO_DIR
set undofile

" Give more space for displaying messages.
set cmdheight=2

" How often the swapfile will be written.
" Also used for the CursorHold autocommand event.
set updatetime=1000

" The time in milliseconds that is waited for a key code or mapped key
" sequence to complete.
set timeoutlen=500

"autocmd InsertEnter * set timeoutlen=300
"autocmd InsertLeave * set timeoutlen=500

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c

"if !has('nvim')
"	set signcolumn=number
"endif
set signcolumn=yes
"augroup numbertoggle
"autocmd!
"autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
"autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
"augroup END

set splitbelow
set splitright

" Quickly enter command mode.
nnoremap <leader>. :

" Switch between horizontal and vertical layouts.
nnoremap <leader>K <C-w>K<CR>
nnoremap <leader>H <C-w>H<CR>

" Hide line numbers in terminal.
"autocmd TermOpen * setlocal nonu

" Quick escape to normal mode.
inoremap jj <ESC>

if has('nvim')
	autocmd TermOpen term://* startinsert
endif

" Open a terminal in new tab in current file dir.
nnoremap tt :let $curdir=expand('%:p:h')<CR>:tabnew<CR>:ter<CR>cd $curdir<CR>

" Vsplit terminal.
nnoremap <leader>, :let $curdir=expand('%:p:h')<CR>:vsplit<CR>:ter<CR>cd $curdir<CR>

" Escape from terminal.
tnoremap <Esc> <C-\><C-n>
tnoremap jj <C-\><C-n>

nnoremap <leader>v :vnew<CR>
nnoremap <leader>s :new<CR>

nnoremap <leader>t :tabnew<CR>

" Move tab to right.
nnoremap <leader>mt :tabm +1<CR>
" Move tab to left.
nnoremap <leader>mT :tabm -1<CR>


" Kill the buffer including terminal process if any.
nnoremap qq :bd!<CR>

" Custom tabline to show tab numbers.
set tabline=%!MyTabLine()

" Go to tab by number
noremap <leader>1 1gt
noremap <leader>2 2gt
noremap <leader>3 3gt
noremap <leader>4 4gt
noremap <leader>5 5gt
noremap <leader>6 6gt
noremap <leader>7 7gt
noremap <leader>8 8gt
noremap <leader>9 9gt
noremap <leader>0 :tablast<cr>

" Switch through buffers.
nnoremap <leader>j :bnext<CR>
nnoremap <leader>k :bprev<CR>
nnoremap <leader>b :Buffers<CR>

" Move focus to window in direction.
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l


" Indent
map <leader>u gg=G

" Escape from search highlight.
nnoremap <Esc><Esc> :nohlsearch<CR>


" Lock the cursor in middle of screen when scrolling.
nnoremap <leader>l :call fns#CursorLockToggle()<CR>

let s:branch = ''

function! Branch()
	return s:branch
endfunction

function! GitBranch()
endfunction

function! UpdateBranch()
	let s:branch = system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
endfunction

" TODO currently using a slow timer instead of autocmd CursorHold
" every time 'system' is called there's a cursor flicker.
call timer_start(10000, { tid -> execute('call UpdateBranch()') }, {'repeat': -1})

"autocmd CursorHold * silent call UpdateBranch()

set statusline=
set statusline+=%#lv15c#
set statusline+=\ %{Branch()}
set statusline+=%#LineNr#
set statusline+=\ %m
set statusline+=\ %f
set statusline+=%=
set statusline+=%#LineNr#
set statusline+=\ %y
set statusline+=\ %{&fileencoding?&fileencoding:&encoding}
set statusline+=\[%{&fileformat}\]
set statusline+=\ %{fns#FileSize()}
set statusline+=\ %p%%
set statusline+=\ %l:%c
set statusline+=\ 

" General settings
set number
set encoding=UTF-8

" Default.
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab 

" Fix yaml indention.
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

" disable vi mode
set nocompatible

"syntax enable
filetype plugin on

set autoindent
set smartindent
filetype indent on
syntax on

set pastetoggle=<F2>

" Reduce cursor flicker when using language plugins.
set noshowcmd noruler

" Always show the status bar.
set laststatus=2

" Search down into subfolders
" Provides tab-completion for all file-related tasks
set path+=**

" Display all matching files when we tab complete
set wildmenu

" Now we can hit tab to :find by partial match
" Use * to make it fuzzy
" :b lets you autocomplete any open buffer

set shell=/bin/bash


" Move current buffer to new tab.
nnoremap <leader>nt :call fns#MoveToNextTab()<CR>

nnoremap <leader>nT :call fns#MoveToPrevTab()<CR>


" Toggle Vista window.
nnoremap <leader>V :Vista!!<CR>
" Toggle symbol finder for the current buffer.
nnoremap <leader>F :Vista finder<CR>

nnoremap <leader>T :Tags<CR>

" By default vista.vim never run if you don't call it explicitly.
"
" If you want to show the nearest function in your statusline automatically,
" you can add the following line to your vimrc 
"autocmd VimEnter * call vista#RunForNearestMethodOrFunction()


" GGrep is git grep.
command! -bang -nargs=* GGrep
			\ call fzf#vim#grep(
			\   'git grep --line-number -- '.shellescape(<q-args>), 0,
			\   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)

" Rg uses ripgrep.
command! -bang -nargs=* Rg
			\ call fzf#vim#grep(
			\   'rg --column --line-number --no-heading --color=always --smart-case -- '.shellescape(<q-args>), 1,
			\   fzf#vim#with_preview(), <bang>0)


nnoremap <leader>g :Rg<CR>

command! -bang -nargs=? -complete=dir Files
			\ call fzf#vim#files(<q-args>, {'options': ['--layout=reverse', '--info=inline', '--preview', '~/.config/nvim/plugged/fzf.vim/bin/preview.sh {}']}, <bang>0)


command! -nargs=+ GotoOrOpen call fns#GotoOrOpen(<f-args>)

let g:fzf_action = {
			\ 'ctrl-t': 'GotoOrOpen tab',
			\ 'ctrl-s': 'split',
			\ 'ctrl-v': 'vsplit' }

let g:fzf_buffers_jump = 1

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


" Search lines in all open buffers.
nnoremap <silent> <leader><Enter> :Lines<CR>

" Open the fzf file finder.
nnoremap <leader>o :FZF<CR>

" TODO ctrl-t doesn't work with this command
nnoremap mru :FZFMru<CR>

" Fuzzy command search.
nnoremap <leader>- :Commands<CR>
nnoremap <leader>/ :Commands<CR>

map <leader>e :NERDTreeToggle<CR>

" Open files in new tab.
let g:netrw_browse_split = 3

" Tree view.
let g:netrw_liststyle = 3

highlight CocHighlightText ctermbg=Grey guibg=#333333
" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
			\ pumvisible() ? "\<C-n>" :
			\ <SID>check_back_space() ? "\<TAB>" :
			\ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
	let col = col('.') - 1
	return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
if exists('*complete_info')
	inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
	imap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
	if (index(['vim','help'], &filetype) >= 0)
		execute 'h '.expand('<cword>')
	else
		call CocAction('doHover')
	endif
endfunction

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Disabled: Show documentation when holding the cursor.
"autocmd CursorHold *.go,*.rs silent call CocAction('doHover')

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Formatting selected code.
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

"augroup mygroup
"autocmd!
" Setup formatexpr specified filetype(s).
"autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
" Update signature help on jump placeholder.
autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
"augroup end

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap keys for applying codeAction to the current line.
nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Introduce function text object
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap if <Plug>(coc-funcobj-i)
omap af <Plug>(coc-funcobj-a)

" Use <TAB> for selections ranges.
" NOTE: Requires 'textDocument/selectionRange' support from the language server.
" coc-tsserver, coc-python are the examples of servers that support it.
"nmap <silent> <TAB> <Plug>(coc-range-select)
"xmap <silent> <TAB> <Plug>(coc-range-select)
autocmd QuickFixCmdPost [^l]* cwindow

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

autocmd BufWritePre *.go
		\  let s:save = winsaveview()
		\| exe 'keepjumps %!gofumports 2>/dev/null || cat /dev/stdin'
		\| call winrestview(s:save)

autocmd BufWritePre *.rs
			\  let s:save = winsaveview()
			\| exe 'keepjumps %!rustfmt 2>/dev/null || cat /dev/stdin'
			\| call winrestview(s:save)

autocmd BufWritePre *.proto
			\  let s:save = winsaveview()
			\| exe 'keepjumps %!clang-format 2>/dev/null || cat /dev/stdin'
			\| call winrestview(s:save)

let g:neomake_typescript_enabled_makers = ['eslint']

autocmd FileType typescript setlocal makeprg=eslint\ --format\ compact

" Lint the directory of current buffer.
"autocmd BufWritePost * Neomake

" Mappings using CoCList:
" Show all diagnostics.
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions.
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands.
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document.
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols.
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list.
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>
