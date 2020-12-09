vim.cmd "packadd pkg-nvim"
require "plugins"
require "nvim-treesitter.configs".setup {
    ensure_installed = "all", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
    highlight = {
        enable = true
    }
}

vim.g.mapleader = ","
vim.g.shfmt_opt = "-ci"
vim.g.neomake_open_list = 2
-- Open fies in new tab.
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

function _G.dump(...)
    local objects = vim.tbl_map(vim.inspect, {...})
    print(unpack(objects))
end

function _G.osc52(content)
    local w = assert(io.open("/dev/tty", "w"))
    assert(w:write(string.format("\x1b]52;c;%s\x1b", require("base64").encode(content))))
    assert(w:close())
end

vim.o.completeopt = "menuone,noinsert,noselect"
vim.o.lazyredraw = true
vim.o.termguicolors = true
vim.cmd("set nofoldenable")
vim.o.hidden = true
vim.cmd("set nobackup")
vim.o.backupcopy = "yes"
vim.o.writebackup = true
vim.o.swapfile = true
vim.o.cmdheight = 2
vim.o.updatetime = 1000
vim.o.timeoutlen = 500
vim.o.signcolumn = "yes:1"
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.encoding = "UTF-8"
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.pastetoggle = "<F2>"
vim.cmd("set noshowcmd")
vim.cmd("set noruler")
vim.cmd("set number")

--vim.o.noshowcmd = true
--vim.o.noruler = true

vim.o.laststatus = 2
vim.o.path = vim.o.path .. "**"
vim.o.runtimepath = vim.o.runtimepath .. ",~/.fzf"
vim.o.wildmenu = true
vim.o.shell = "/bin/bash"
vim.cmd("filetype plugin on")
vim.cmd("filetype indent on")
vim.cmd("syntax on")
vim.cmd("colorscheme codedark")
vim.cmd("set tabline=%!MyTabLine()")

local vimp = require "vimp"

vimp.vnoremap("Y", [["+y<CR>]])
vimp.inoremap("jj", "<Esc>")
vimp.tnoremap("<Esc>", [[<C-\><C-n>]])
vimp.nnoremap("<Esc><Esc>", ":nohlsearch<CR>")

vimp.nnoremap("<leader>.", ":")
vimp.nnoremap("<leader>-", ":Commands<CR>")
vimp.nnoremap("<leader>/", ":Commands<CR>")
vimp.nnoremap("<leader>,", ":let $curdir=expand('%:p:h')<CR>:vsplit<CR>:ter<CR>cd $curdir<CR>")
vimp.nnoremap("tt", ":let $curdir=expand('%:p:h')<CR>:tabnew<CR>:ter<CR>cd $curdir<CR>")
vimp.nnoremap("<leader>v", ":vnew<CR>")
vimp.nnoremap("<leader>s", ":new<CR>")
vimp.nnoremap("<leader>t", ":tabnew<CR>")
vimp.nnoremap("<leader>e", ":Tex<CR>")
vimp.nnoremap("<leader>j", ":bnext<CR>")
vimp.nnoremap("<leader>k", ":bprev<CR>")
vimp.nnoremap("<leader>b", ":Buffers<CR>")
vimp.nnoremap("<leader>u", "gg=G``")
vimp.nnoremap("<leader>g", ":Rg<CR>")
vimp.nnoremap("<leader>o", ":FZF<CR>")
vimp.nnoremap(
    "<leader>l",
    function()
        vim.call("fns#CursorLockToggle")
    end
)
vimp.nnoremap("<leader>K", "<C-w>K<CR>")
vimp.nnoremap("<leader>H", "<C-w>H<CR>")
vimp.nnoremap("<leader>T", ":Tags<CR>")

vimp.nnoremap("<C-h>", "<C-w>h")
vimp.nnoremap("<C-j>", "<C-w>j")
vimp.nnoremap("<C-k>", "<C-w>k")
vimp.nnoremap("<C-l>", "<C-w>l")
vimp.nnoremap("qq", ":bd!<CR>")

vimp.nnoremap(
    "<leader>nt",
    function()
        vim.call("fns#MoveToNextTab")
    end
)
vimp.nnoremap(
    "<leader>nT",
    function()
        vim.call("fns#MoveToPrevTab")
    end
)
vimp.nnoremap("<leader>mt", ":tabm +1<CR>")
vimp.nnoremap("<leader>mT", ":tabm -1<CR>")
for i = 1, 9 do
    vimp.nnoremap(string.format("<leader>%d", i), string.format("%dgt", i))
end
vimp.nnoremap("<leader>0", ":tablast<CR>")

vimp.inoremap({"expr"}, "<Tab>", [[pumvisible() ? "\<C-n>" : "\<Tab>"]])
vimp.inoremap({"expr"}, "<S-Tab>", [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]])

vimp.nnoremap({"silent"}, "<space>a", vim.lsp.diagnostic.set_loclist)
vimp.nnoremap({"silent"}, "<space>j", vim.lsp.diagnostic.goto_next)
vimp.nnoremap({"silent"}, "<space>k", vim.lsp.diagnostic.goto_prev)
vimp.nnoremap({"silent"}, "gd", vim.lsp.buf.definition)
vimp.nnoremap({"silent"}, "<leader>rn", vim.lsp.buf.rename)
vimp.nnoremap(
    {"silent"},
    "K",
    function()
        vim.call("fns#ShowDocs")
    end
)
vimp.nnoremap({"silent"}, "gD", vim.lsp.buf.implementation)
vimp.nnoremap({"silent"}, "gr", vim.lsp.buf.references)
vimp.nnoremap({"silent"}, "g0", vim.lsp.buf.document_symbol)
vimp.nnoremap({"silent"}, "gW", vim.lsp.buf.workspace_symbol)

local api = vim.api
local util = vim.lsp.util
local callbacks = vim.lsp.callbacks
local log = vim.lsp.log

-- open everything in new tab
local location_callback = function(_, method, result)
    if result == nil or vim.tbl_isempty(result) then
        local _ = log.info() and log.info(method, "No location found")
        return nil
    end

    -- create a new tab and save bufnr
    api.nvim_command("tabnew")
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
    api.nvim_command(buf .. "bd")
end

callbacks["textDocument/declaration"] = location_callback
callbacks["textDocument/definition"] = location_callback
callbacks["textDocument/typeDefinition"] = location_callback
callbacks["textDocument/implementation"] = location_callback

local attach = function(client)
    require "completion".on_attach(client)
end

local lsp = require "lspconfig"

lsp.gopls.setup {on_attach = attach}
lsp.clangd.setup {on_attach = attach}
lsp.jsonls.setup {on_attach = attach}
lsp.intelephense.setup {on_attach = attach}
lsp.rls.setup {on_attach = attach}
lsp.tsserver.setup {on_attach = attach}
lsp.vimls.setup {on_attach = attach}
lsp.yamlls.setup {on_attach = attach}
lsp.html.setup {on_attach = attach}
lsp.cssls.setup {on_attach = attach}
lsp.bashls.setup {on_attach = attach}
