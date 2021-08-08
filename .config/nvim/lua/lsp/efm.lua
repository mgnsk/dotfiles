local autoformat_enabled = true

function autoformat_toggle()
    autoformat_enabled = not autoformat_enabled
end

vim.cmd("command AutoformatToggle lua autoformat_toggle()")

function do_format()
    if autoformat_enabled then
        vim.lsp.buf.formatting_sync(nil, 5000)
    end
end

-- TODO this was previously used for vimscript indentation
-- execute('normal gg=G``')

local luafmt = require "lsp/efm/luafmt"
local prettier = require "lsp/efm/prettier"
local clang = require "lsp/efm/clang-format"
local goimports = require "lsp/efm/goimports"
local sed = require "lsp/efm/sed"
local rustfmt = require "lsp/efm/rustfmt"
local shfmt = require "lsp/efm/shfmt"
local dockerfilefmt = require "lsp/efm/dockerfile-fmt"
local sqlfmt = require "lsp/efm/sqlfmt"

local languages = {
    -- TODO why doesn't work?
    -- ["="] = {sed},
    lua = {luafmt},
    go = {goimports},
    oss = {prettier},
    scss = {prettier},
    yaml = {prettier},
    markdown = {prettier},
    html = {prettier},
    json = {prettier},
    javascript = {prettier},
    typescript = {prettier},
    glsl = {clang},
    proto = {clang},
    rust = {rustfmt},
    sh = {shfmt},
    dockerfile = {dockerfilefmt},
    sql = {sqlfmt}
}

-- efm is a generic language server used for diff-based formatting
require "lspconfig".efm.setup {
    on_attach = function(client)
        if client.resolved_capabilities.document_formatting then
            vim.api.nvim_command [[augroup Format]]
            vim.api.nvim_command [[autocmd! * <buffer>]]
            vim.api.nvim_command [[autocmd BufWritePre <buffer> lua do_format()]]
            vim.api.nvim_command [[augroup END]]
        end
    end,
    init_options = {documentFormatting = true},
    root_dir = vim.loop.cwd,
    settings = {
        rootMarkers = {".git/", "go.mod", "package.json"},
        languages = languages
    },
    filetypes = vim.tbl_keys(languages)
}
