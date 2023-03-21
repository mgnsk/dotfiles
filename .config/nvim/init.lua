vim.o.encoding = "UTF-8"
vim.o.pastetoggle = "<F2>"
vim.o.path = vim.o.path .. "**"
vim.o.shell = os.getenv("SHELL")
vim.cmd("syntax on")
vim.cmd("set t_ut=")
-- TODO what does this do?
--vim.cmd("set noruler")

require("persistent_undo")
require("editor")
require("indent")
require("autocommands")
require("mappings")
require("tabline")
require("statusline")

require("plugins")
