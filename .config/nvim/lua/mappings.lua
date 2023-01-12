local opts = { noremap = true, silent = true }
local fzf = require("fzf-lua")

fzf.setup({
    winopts = {
        preview = {
            delay = 0,
        },
    },
    grep = {
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=512 --hidden --glob=!.git/",
    },
})

vim.keymap.set("v", "Y", [["+y<CR>]], opts)
vim.keymap.set("i", "jj", "<Esc>", opts)
vim.keymap.set("t", "jj", [[<C-\><C-n>]], opts)

vim.keymap.set("n", "qq", function()
    vim.call("fns#BD")
end)

vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])
vim.keymap.set("n", "<Esc><Esc>", ":nohlsearch<CR>")

vim.keymap.set("n", "<leader>.", ":")
vim.keymap.set("n", "<leader>,", ":let $curdir=expand('%:p:h')<CR>:vsplit<CR>:ter<CR>cd $curdir<CR>")
vim.keymap.set("n", "tt", ":let $curdir=expand('%:p:h')<CR>:tabnew<CR>:ter<CR>cd $curdir<CR>")
vim.keymap.set("n", "<leader>v", ":vnew<CR>")
vim.keymap.set("n", "<leader>s", ":new<CR>")
vim.keymap.set("n", "<leader>t", ":tabnew<CR>")
vim.keymap.set("n", "<leader>e", ":Tex<CR>")
vim.keymap.set("n", "<leader>j", ":bnext<CR>")
vim.keymap.set("n", "<leader>k", ":bprev<CR>")
vim.keymap.set("n", "<leader>u", "gg=G``")

vim.keymap.set("n", "<leader>c", require("neoclip.fzf"))
vim.keymap.set("n", "<leader>p", fzf.builtin)
vim.keymap.set("n", "<leader>/", fzf.commands)
vim.keymap.set("n", "<leader>b", fzf.buffers)
-- Grep a single pattern.
vim.keymap.set("n", "<leader>g", fzf.live_grep)
-- Grep all words separately, including filename.
vim.keymap.set("n", "<leader>a", function()
    fzf.grep_project({ fzf_opts = { ["--nth"] = false } })
end)
vim.keymap.set("n", "<leader>o", fzf.files)
vim.keymap.set("n", "<leader>T", fzf.tags)
vim.keymap.set("n", "<leader>f", fzf.lsp_document_symbols)
vim.keymap.set("n", "<leader>F", fzf.lsp_live_workspace_symbols)
vim.keymap.set("n", "<leader>G", fzf.git_bcommits)

vim.keymap.set("n", "<leader>B", ":Gblame<CR>")
vim.keymap.set("n", "<leader>W", ":Gw!<CR>")
vim.keymap.set("n", "<leader>V", ":Vista<CR>")

vim.keymap.set("n", "<leader>l", function()
    if vim.wo.scrolloff > 0 then
        vim.wo.scrolloff = 0
    else
        vim.wo.scrolloff = 999
    end
end)

vim.keymap.set("n", "<leader>K", "<C-w>K<CR>")
vim.keymap.set("n", "<leader>H", "<C-w>H<CR>")

vim.keymap.set("n", "<leader>mt", ":tabm +1<CR>")
vim.keymap.set("n", "<leader>mT", ":tabm -1<CR>")

for i = 1, 9 do
    vim.keymap.set("n", string.format("<leader>%d", i), string.format("%dgt", i))
end
vim.keymap.set("n", "<leader>0", ":tablast<CR>")

vim.keymap.set("n", "gj", vim.diagnostic.goto_next, opts)
vim.keymap.set("n", "gk", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
vim.keymap.set("n", "ga", vim.lsp.buf.code_action, opts)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
vim.keymap.set("n", "gD", vim.lsp.buf.implementation, opts)
vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

vim.keymap.set("n", "gn", function()
    require("illuminate").goto_next_reference(false)
end, opts)

vim.keymap.set("n", "gp", function()
    require("illuminate").goto_prev_reference(false)
end, opts)
