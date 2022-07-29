local api = vim.api
local util = vim.lsp.util
local handlers = vim.lsp.handlers
local lsp = require "lspconfig"

-- local capabilities = require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities())
local capabilities = vim.lsp.protocol.make_client_capabilities()

local function on_attach(client, bufnr)
    client.server_capabilities.document_formatting = false
    require "lsp_signature".on_attach()
    require "illuminate".on_attach(client)
end

lsp.gopls.setup {capabilities = capabilities, on_attach = on_attach}
lsp.intelephense.setup {capabilities = capabilities, on_attach = on_attach}
lsp.rust_analyzer.setup {capabilities = capabilities, on_attach = on_attach}
lsp.tsserver.setup {capabilities = capabilities, on_attach = on_attach}
lsp.html.setup {capabilities = capabilities, on_attach = on_attach}
lsp.cssls.setup {capabilities = capabilities, on_attach = on_attach}
lsp.bashls.setup {capabilities = capabilities, on_attach = on_attach}
lsp.yamlls.setup {
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {
        yaml = {
            schemas = {
                ["https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.0/schema.yaml"] = {
                    "openapi3.yml",
                    "openapi3.yaml"
                }
            }
        }
    }
}

-- location_callback opens all LSP gotos in a new tab
local location_callback = function(_, result, ctx)
    if result == nil or vim.tbl_isempty(result) then
        local _ = vim.lsp.log.info() and vim.lsp.log.info(ctx["method"], "No location found")
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

vim.api.nvim_exec([[
command LspStop lua vim.lsp.stop_client(vim.lsp.get_active_clients())
]], true)

vim.api.nvim_command [[autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()]]
vim.api.nvim_command [[autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()]]
vim.api.nvim_command [[autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()]]

vim.api.nvim_command [[ hi def link LspReferenceText CursorLine ]]
vim.api.nvim_command [[ hi def link LspReferenceWrite CursorLine ]]
vim.api.nvim_command [[ hi def link LspReferenceRead CursorLine ]]
