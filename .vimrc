source ~/.vim/plugins.vim

set runtimepath+=~/.fzf

let mapleader = ','

lua << EOF
local api = vim.api
local util = vim.lsp.util
local callbacks = vim.lsp.callbacks
local log = vim.lsp.log

local location_callback = function(_, method, result)
  if result == nil or vim.tbl_isempty(result) then
  local _ = log.info() and log.info(method, 'No location found')
  return nil
  end

  -- create a new tab and save bufnr
  api.nvim_command('tabnew')
  local buf = api.nvim_get_current_buf()

  if vim.tbl_islist(result) then
    util.jump_to_location(result[1])
    if #result > 1 then
      util.set_qflist(util.locations_to_items(result))
      api.nvim_command("copen")
    end
  else
    local buf = api.nvim_get_current_buf()
  end

  -- remove the empty buffer created with tabnew
  api.nvim_command(buf .. 'bd')
end

callbacks['textDocument/declaration']    = location_callback
callbacks['textDocument/definition']     = location_callback
callbacks['textDocument/typeDefinition'] = location_callback
callbacks['textDocument/implementation'] = location_callback

local on_attach_vim = function(client)
  require'completion'.on_attach(client)
  require'diagnostic'.on_attach(client)
end

require'nvim_lsp'.gopls.setup{on_attach=on_attach_vim}
require'nvim_lsp'.clangd.setup{on_attach=on_attach_vim}
require'nvim_lsp'.jsonls.setup{on_attach=on_attach_vim}
require'nvim_lsp'.intelephense.setup{on_attach=on_attach_vim}
require'nvim_lsp'.rls.setup{on_attach=on_attach_vim}
require'nvim_lsp'.tsserver.setup{on_attach=on_attach_vim}
require'nvim_lsp'.vimls.setup{on_attach=on_attach_vim}
require'nvim_lsp'.yamlls.setup{on_attach=on_attach_vim}
require'nvim_lsp'.html.setup{on_attach=on_attach_vim}
EOF

" use omni completion provided by lsp, seems to work by itself
"autocmd Filetype go,rust setlocal omnifunc=v:lua.vim.lsp.omnifunc

" Use <Tab> and <S-Tab> to navigate through popup menu
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

nnoremap <silent> <space>a  :OpenDiagnostic<cr>
let g:diagnostic_enable_virtual_text = 1

" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect

" Avoid showing message extra message when using completion
set shortmess+=c


nnoremap <silent> gd <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <leader>rn <cmd>lua vim.lsp.buf.rename()<CR>
nnoremap <silent> K :call fns#ShowDocs()<CR>
nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>

nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>

"nnoremap <silent> gd    <cmd>lua vim.lsp.buf.declaration()<CR>
"nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
"nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>

let g:neomake_open_list = 2

" the configuration options should be placed before `colorscheme sonokai`
let g:sonokai_style = 'atlantis'
let g:sonokai_enable_italic = 0
let g:sonokai_disable_italic_comment = 0

"let g:rainbow_active = 1
"let g:rainbow_guifgs = [
			"\ '#458588',
			"\ '#d19a66',
			"\ '#2D72AB',
			"\ '#d65d0e',
			"\ '#458588',
			"\ '#b16286',
			"\ '#78cee9',
			"\ '#d65d0e',
			"\ '#458588',
			"\ '#b16286',
			"\ '#98c379',
			"\ '#d65d0e',
			"\ '#458588',
			"\ '#b16286',
			"\ '#ff6d7e',
			"\ '#d65d0e',
			"\ ]

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


set nofoldenable

" TextEdit might fail if hidden is not set.
set hidden

set nobackup
set backupcopy=yes
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


set signcolumn=yes

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

nnoremap <leader>T :Tags<CR>

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

" TODO ctrl-t doesn't work with this command
nnoremap mru :FZFMru<CR>

" Search lines in all open buffers.
nnoremap <silent> <leader><Enter> :Lines<CR>

" Open the fzf file finder.
nnoremap <leader>o :FZF<CR>


" Fuzzy command search.
nnoremap <leader>- :Commands<CR>
nnoremap <leader>/ :Commands<CR>

map <leader>e :Tex<CR>

" Open files in new tab.
let g:netrw_browse_split = 3

" Tree view.
let g:netrw_liststyle = 3
