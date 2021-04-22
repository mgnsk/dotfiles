local api = vim.api
local util = vim.lsp.util
local handlers = vim.lsp.handlers
local log = vim.lsp.log
local vimp = require "vimp"
local lsp = require "lspconfig"

lsp.gopls.setup {}
lsp.clangd.setup {}
lsp.jsonls.setup {}
lsp.intelephense.setup {}
lsp.rust_analyzer.setup {}
lsp.tsserver.setup {}
lsp.vimls.setup {}
lsp.yamlls.setup {}
lsp.html.setup {}
lsp.cssls.setup {}
lsp.bashls.setup {}

local location_callback = function(_, method, result)
    if result == nil or vim.tbl_isempty(result) then
        local _ = log.info() and log.info(method, "No location found")
        return nil
    end

    api.nvim_command("tab split")

    if vim.tbl_islist(result) then
        util.jump_to_location(result[1])
        if #result > 1 then
            util.set_qflist(util.locations_to_items(result))
            api.nvim_command("copen")
            api.nvim_command("wincmd p")
        end
    else
        util.jump_to_location(result)
    end
end

handlers["textDocument/declaration"] = location_callback
handlers["textDocument/definition"] = location_callback
handlers["textDocument/typeDefinition"] = location_callback
handlers["textDocument/implementation"] = location_callback

vimp.nnoremap({"silent"}, "<space>a", vim.lsp.diagnostic.set_loclist)
vimp.nnoremap({"silent"}, "<space>j", vim.lsp.diagnostic.goto_next)
vimp.nnoremap({"silent"}, "<space>k", vim.lsp.diagnostic.goto_prev)
vimp.nnoremap({"silent"}, "gd", vim.lsp.buf.definition)
vimp.nnoremap({"silent"}, "ga", vim.lsp.buf.code_action)
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

vim.api.nvim_exec(
    [[
command LspStop lua vim.lsp.stop_client(vim.lsp.get_active_clients())
autocmd CursorHold * lua vim.lsp.diagnostic.show_line_diagnostics()
]],
    true
)
