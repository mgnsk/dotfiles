call plug#begin()
Plug 'preservim/nerdcommenter'
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'nvim-treesitter/nvim-treesitter'
" Although vim-polyglot is not needed when using treesitter
" it's still kept to highlight filetypes which treesitter doesn't support.
Plug 'sheerun/vim-polyglot'
Plug 'junegunn/fzf.vim'
Plug 'airblade/vim-gitgutter'
" Only used for the GoCoverage command.
Plug 'arp242/gopher.vim', {'for': 'go'}
Plug 'sebdah/vim-delve', {'for': 'go'}
Plug 'Townk/vim-autoclose'
Plug 'neomake/neomake'
Plug 'tpope/vim-fugitive'
Plug 'sbdchd/neoformat'
Plug 'rbtnn/vim-vimscript_indentexpr'
call plug#end()
