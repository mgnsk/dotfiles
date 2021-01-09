local vimp = require "vimp"

vimp.vnoremap("Y", [["+y<CR>]])
vimp.inoremap("jj", "<Esc>")
vimp.tnoremap("jj", [[<C-\><C-n>]])

vimp.nnoremap(
    "qq",
    function()
        vim.call("fns#BD")
    end
)

vimp.nnoremap("<C-h>", "<C-w>h")
vimp.nnoremap("<C-j>", "<C-w>j")
vimp.nnoremap("<C-k>", "<C-w>k")
vimp.nnoremap("<C-l>", "<C-w>l")
vimp.tnoremap("<Esc>", [[<C-\><C-n>]])
vimp.nnoremap("<Esc><Esc>", ":nohlsearch<CR>")

vimp.nnoremap("<leader>.", ":")
vimp.nnoremap("<leader>,", ":let $curdir=expand('%:p:h')<CR>:vsplit<CR>:ter<CR>cd $curdir<CR>")
vimp.nnoremap("tt", ":let $curdir=expand('%:p:h')<CR>:tabnew<CR>:ter<CR>cd $curdir<CR>")
vimp.nnoremap("<leader>v", ":vnew<CR>")
vimp.nnoremap("<leader>s", ":new<CR>")
vimp.nnoremap("<leader>t", ":tabnew<CR>")
vimp.nnoremap("<leader>e", ":Tex<CR>")
vimp.nnoremap("<leader>j", ":bnext<CR>")
vimp.nnoremap("<leader>k", ":bprev<CR>")
vimp.nnoremap("<leader>u", "gg=G``")

vimp.nnoremap("<leader>-", ":Commands<CR>")
vimp.nnoremap("<leader>/", ":Commands<CR>")
vimp.nnoremap("<leader>b", ":Buffers<CR>")
vimp.nnoremap("<leader>g", ":RG<CR>")
vimp.nnoremap("<leader>o", ":FZF<CR>")
vimp.nnoremap("<leader>T", ":Tags<CR>")
vimp.nnoremap("<leader>F", ":DocumentSymbols<CR>")
vimp.nnoremap("<leader>G", ":BCommits<CR>")

vimp.nnoremap(
    "<leader>l",
    function()
        vim.call("fns#CursorLockToggle")
    end
)
vimp.nnoremap("<leader>K", "<C-w>K<CR>")
vimp.nnoremap("<leader>H", "<C-w>H<CR>")

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
