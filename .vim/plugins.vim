call plug#begin()
Plug 'preservim/nerdcommenter'
Plug 'preservim/nerdtree', {'on':  'NERDTreeToggle'}
Plug 'Xuyuanp/nerdtree-git-plugin', {'on':  'NERDTreeToggle'}
Plug 'PhilRunninger/nerdtree-visual-selection', {'on':  'NERDTreeToggle'}
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'jackguo380/vim-lsp-cxx-highlight'
Plug 'junegunn/fzf.vim'
Plug 'airblade/vim-gitgutter'
Plug 'arp242/gopher.vim', {'for': 'go'}
Plug 'rust-lang/rust.vim', {'for': 'rust'}
Plug 'liuchengxu/vista.vim'
Plug 'Townk/vim-autoclose'
Plug 'StanAngeloff/php.vim', {'for': 'php'}
Plug 'neomake/neomake'
Plug 'tpope/vim-fugitive'

" coc.nvim extensions.
Plug 'josa42/coc-docker', {'do': 'yarn install --frozen-lockfile'}
Plug 'clangd/coc-clangd', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-json', {'do': 'yarn install --frozen-lockfile'}
Plug 'marlonfan/coc-phpls', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-rls', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-tsserver', {'do': 'yarn install --frozen-lockfile'}
Plug 'iamcco/coc-vimlsp', {'do': 'yarn install --frozen-lockfile'}
Plug 'neoclide/coc-yaml', {'do': 'yarn install --frozen-lockfile'}
call plug#end()
