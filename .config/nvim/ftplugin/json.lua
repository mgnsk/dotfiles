vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.tabstop = 2

require("conform").formatters_by_ft.json = { "prettier" }

-- show json path in the winbar
if vim.fn.exists("+winbar") == 1 then
	vim.opt_local.winbar = "%{%v:lua.require'jsonpath'.get()%}"
end
