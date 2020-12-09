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
