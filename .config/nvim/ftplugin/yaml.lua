vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.tabstop = 2

-- Note: formatting disabled.
-- require("file_actions").configureFormatBeforeSave({ lsp_format = "fallback" })
require("file_actions").configureLintAfterSave({ "yamllint" })
