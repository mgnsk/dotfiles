vim.g.completion_chain_complete_list = {
    default = {
        {complete_items = {"lsp"}},
        {complete_items = {"buffers"}},
        {complete_items = {"ts"}}, -- treesitter source
        {mode = {"<c-p>"}},
        {mode = {"<c-n>"}}
    }
}
vim.g.completion_auto_change_source = 1

vim.api.nvim_exec([[
autocmd BufEnter * lua require'completion'.on_attach()
    :set number relativenumber
]], true)
