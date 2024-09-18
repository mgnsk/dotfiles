vim.bo.expandtab = true
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.tabstop = 4

if vim.fn.filereadable(vim.fn.resolve(vim.fn.getcwd() .. "/pint.json")) then
	require("file_actions").configureFormatBeforeSave({ "pint" })
end

require("file_actions").configureLintAfterSave({ "phpstan" })
