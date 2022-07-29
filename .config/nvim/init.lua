vim.g.mapleader = ","
vim.g.autoformat_enabled = false

require("kommentary.config").configure_language("default", {
    prefer_single_line_comments = true,
})

if not os.getenv("NVIM_DIFF") then
    vim.g.autoformat_enabled = true
    vim.call("neomake#configure#automake", "w")
    require("lsp")
    require("formatting")
    require("autocomplete")
end

require("mappings")
require("osc52")

require("nvim-treesitter.configs").setup({
    --ensure_installed = "all", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
    highlight = { enable = true },
    --incremental_selection = {enable = true},
    --textobjects = {enable = true}
})

vim.api.nvim_exec(
    [[
au BufRead,BufNewFile *.tla set filetype=tla
]],
    true
)

local undodir = os.getenv("VIM_UNDO_DIR")
if not vim.call("isdirectory", undodir) then
    vim.call("mkdir", undodir)
end
vim.o.undodir = undodir
vim.cmd("set undofile")
vim.cmd("set noexpandtab")
vim.cmd("set nocompatible")
vim.cmd("set termguicolors")
---- TODO check what else only works with vim.cmd
vim.cmd("set nofoldenable")
vim.o.hidden = true
vim.cmd("set nobackup")
vim.o.backupcopy = "yes"
vim.o.writebackup = true
vim.o.swapfile = true
--vim.o.cmdheight = 2
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
vim.o.lazyredraw = true
vim.cmd("set number")
vim.o.laststatus = 2
vim.o.path = vim.o.path .. "**"
--vim.o.runtimepath = vim.o.runtimepath .. ",/usr/share/vim/vimfiles/plugin"
vim.o.wildmenu = true
vim.o.shell = os.getenv("SHELL")
vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")
vim.cmd("set tabstop=4 softtabstop=4 shiftwidth=4 expandtab")
vim.cmd("colorscheme codedarker")
vim.cmd("set tabline=%!MyTabLine()")
-- TODO what does this do?
--vim.cmd("set noruler")

-- Visible whitespace disabled by default.
-- vim.cmd("set list")
vim.cmd("set lcs+=space:·")

-- Use the `default_options` as the second parameter, which uses
-- `foreground` for every mode. This is the inverse of the previous
-- setup configuration.
require("colorizer").setup({
    "*", -- Highlight all files, but customize some others.
    css = { rgb_fn = true }, -- Enable parsing rgb(...) functions in css.
    html = { names = false }, -- Disable parsing "names" like Blue or Gray
})

vim.g.neomake_open_list = 2
-- Open files in new tab.
vim.g.netrw_browse_split = 3
-- Tree view.
vim.g.netrw_liststyle = 3

vim.g.fzf_action = {
    ["ctrl-t"] = "GotoOrOpen tab",
    ["ctrl-s"] = "split",
    ["ctrl-v"] = "vsplit",
}
vim.g.fzf_buffers_jump = 1
vim.g.gitgutter_sign_columns_always = 1

vim.g.Illuminate_delay = 500

vim.api.nvim_command([[ set t_ut= ]])
