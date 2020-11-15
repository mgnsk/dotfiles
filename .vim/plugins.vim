call plug#begin()
Plug 'preservim/nerdcommenter'
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'junegunn/fzf.vim'
Plug 'airblade/vim-gitgutter'
Plug 'arp242/gopher.vim', {'for': 'go'}
Plug 'sebdah/vim-delve', {'for': 'go'}
Plug 'Townk/vim-autoclose'
Plug 'neomake/neomake'
Plug 'tpope/vim-fugitive'
Plug 'sbdchd/neoformat'
Plug 'sheerun/vim-polyglot'
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }
Plug 'rbtnn/vim-vimscript_indentexpr'
call plug#end()
