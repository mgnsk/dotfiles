require("lazy_init")
require("plugins")
require("mappings")
require("osc52")
require("persistent_undo")
require("ui")
require("indent")
require("autocommands")
require("statusline")
require("tabline")

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

function _G.file_size()
    local file = vim.fn.expand("%:p")
    if string.len(file) == 0 then
        return ""
    end

    local size = vim.fn.getfsize(file)
    if size <= 0 then
        return ""
    end

    local units = { "B", "KB", "MB", "GB" }

    local i = 1
    while size > 1024 do
        size = size / 1024
        i = i + 1
    end

    local unit = units[i]
    local format = unit == "B" and "%.0f%s" or "%.1f%s"
    return string.format(format, size, unit)
end
