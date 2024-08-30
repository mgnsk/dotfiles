vim.bo.expandtab = true
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.tabstop = 4

require("conform").formatters_by_ft.fish = { "fish_indent" }
