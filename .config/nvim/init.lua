vim.o.encoding = "UTF-8"
vim.o.pastetoggle = "<F2>"
vim.o.path = vim.o.path .. "**"
vim.o.shell = os.getenv("SHELL")
vim.cmd("syntax on")
vim.cmd("set t_ut=")
-- TODO what does this do?
--vim.cmd("set noruler")

-- Visible whitespace disabled by default.
-- vim.cmd("set list")
vim.cmd("set lcs+=space:·")

require("persistent_undo")
require("editor")
require("indent")
require("autocommands")
require("osc52")
require("mappings")
require("tabline")
require("statusline")

require("plugins")
