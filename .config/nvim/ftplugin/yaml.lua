vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.tabstop = 2

-- TODO: better ftplugin and append linters
if vim.bo.filetype == "yaml.ansible" then
	require("file_actions").configureLintAfterSave({ "yamllint", "ansiblelint" })
else
	require("file_actions").configureLintAfterSave({ "yamllint" })
end
