vim.cmd "packadd pkg-nvim"

vim.g.mapleader = ","
require "mappings"
require "formatter"
if not os.getenv("NVIM_LSP_DISABLED") then
    require "lsp"
end

require "nvim-treesitter.configs".setup {
    ensure_installed = "all", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
    highlight = {
        enable = true
    }
}

vim.call("neomake#configure#automake", "w")

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
vim.o.wildmenu = true
vim.o.shell = "/bin/bash"
vim.cmd("filetype plugin on")
vim.cmd("filetype indent on")
vim.cmd("syntax on")
vim.cmd("colorscheme codedark")
vim.cmd("set tabline=%!MyTabLine()")

require "colorizer".setup()

vim.g.neomake_open_list = 2
-- Open fies in new tab.
vim.g.netrw_browse_split = 3
-- Tree view.
vim.g.netrw_liststyle = 3

vim.g.gitgutter_sign_columns_always = 1

function _G.osc52(content)
    local w = assert(io.open("/dev/tty", "w"))
    assert(w:write(string.format("\x1b]52;c;%s\x1b", require("base64").encode(content))))
    assert(w:close())
end
