vim.bo.expandtab = true
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.tabstop = 4

require("file_actions").configureFormatBeforeSave({ "fish_indent" })
require("file_actions").configureLintAfterSave({ "fish" })
