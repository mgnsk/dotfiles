vim.cmd "packadd pkg-nvim"

vim.g.mapleader = ","
vim.g.autoformat_enabled = false

if not os.getenv("NVIM_DIFF") then
    vim.g.autoformat_enabled = true
    vim.call("neomake#configure#automake", "w")
    require "lsp"
end

require "mappings"
require "formatter"
require "osc52"

require "nvim-treesitter.configs".setup {
    ensure_installed = "all", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
    highlight = {enable = true}
    --incremental_selection = {enable = true},
    --textobjects = {enable = true}
}

local undodir = os.getenv("VIM_UNDO_DIR")
if not vim.call("isdirectory", undodir) then
    vim.call("mkdir", undodir)
end
vim.o.undodir = undodir
vim.cmd("set undofile")
vim.cmd("set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab")
vim.cmd("set noexpandtab")
vim.cmd("set nocompatible")
vim.o.completeopt = "menuone,noinsert,noselect"
vim.o.lazyredraw = true
vim.cmd("set termguicolors")
-- TODO check what else only works with vim.cmd
vim.cmd("set nofoldenable")
vim.o.hidden = true
vim.cmd("set nobackup")
vim.o.backupcopy = "yes"
vim.o.writebackup = true
vim.o.swapfile = true
vim.o.cmdheight = 2
vim.o.updatetime = 1000
vim.o.timeoutlen = 500
vim.cmd("set signcolumn=yes")
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.encoding = "UTF-8"
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.pastetoggle = "<F2>"
vim.cmd("set noshowcmd")
vim.cmd("set noruler")
vim.cmd("set number")
vim.o.laststatus = 2
vim.o.path = vim.o.path .. "**"
vim.o.runtimepath = vim.o.runtimepath .. ",/usr/share/vim/vimfiles/plugin"
vim.o.wildmenu = true
vim.o.shell = "/bin/bash"
vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")
vim.cmd("colorscheme codedark")
vim.cmd("set tabline=%!MyTabLine()")

require "colorizer".setup()

vim.g.neomake_open_list = 2
-- Open files in new tab.
vim.g.netrw_browse_split = 3
-- Tree view.
vim.g.netrw_liststyle = 3

vim.g.fzf_action = {
    ["ctrl-t"] = "GotoOrOpen tab",
    ["ctrl-s"] = "split",
    ["ctrl-v"] = "vsplit"
}
vim.g.fzf_buffers_jump = 1
vim.g.gitgutter_sign_columns_always = 1
