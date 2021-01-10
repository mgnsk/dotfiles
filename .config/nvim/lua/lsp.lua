local api = vim.api
local util = vim.lsp.util
local callbacks = vim.lsp.callbacks
local log = vim.lsp.log
local vimp = require "vimp"

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

local on_attach = function(client)
    require "completion".on_attach(client)
end

local lsp = require "lspconfig"

lsp.gopls.setup {on_attach = on_attach}
lsp.clangd.setup {on_attach = on_attach}
lsp.jsonls.setup {on_attach = on_attach}
lsp.intelephense.setup {on_attach = on_attach}
lsp.rust_analyzer.setup {on_attach = on_attach}
lsp.tsserver.setup {on_attach = on_attach}
lsp.vimls.setup {on_attach = on_attach}
lsp.yamlls.setup {on_attach = on_attach}
lsp.html.setup {on_attach = on_attach}
lsp.cssls.setup {on_attach = on_attach}
lsp.bashls.setup {on_attach = on_attach}

callbacks["textDocument/declaration"] = location_callback
callbacks["textDocument/definition"] = location_callback
callbacks["textDocument/typeDefinition"] = location_callback
callbacks["textDocument/implementation"] = location_callback

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
