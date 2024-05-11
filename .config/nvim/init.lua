vim.cmd("set nocompatible")
vim.cmd("set termguicolors")
vim.cmd("set nofoldenable")
vim.cmd("set noshowcmd")
vim.o.hidden = true
vim.o.updatetime = 500
vim.o.timeoutlen = 500
vim.opt.number = true
vim.opt.signcolumn = "yes" -- TODO
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.lazyredraw = true
vim.o.laststatus = 2
vim.o.wildmenu = true
vim.o.scrolloff = 999
vim.o.wrap = true
vim.o.inccommand = "split"
vim.o.encoding = "UTF-8"
vim.o.path = vim.o.path .. "**"
vim.o.shell = os.getenv("SHELL")

vim.cmd("set list") -- visible whitespace
vim.cmd("set lcs+=space:·")
vim.cmd("set switchbuf+=newtab")
vim.cmd("syntax on")
vim.cmd("set t_ut=")
-- TODO what does this do?
--vim.cmd("set noruler")
--

vim.g.netrw_banner = 0
-- Tree view.
vim.g.netrw_liststyle = 3
vim.g.netrw_bufsettings = "noma nomod nu nobl nowrap ro"
-- Open files in new tab.
vim.g.netrw_browse_split = 3
-- Preview in vertical split.
vim.g.netrw_preview = 1
vim.g.netrw_alto = 0
vim.g.netrw_winsize = 30

vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave" }, {
	callback = function()
		vim.o.relativenumber = true
	end,
})
vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave" }, {
	callback = function()
		vim.o.relativenumber = true
	end,
})

vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter" }, {
	callback = function()
		vim.o.relativenumber = false
	end,
})

vim.api.nvim_create_autocmd("TermOpen", {
	command = [[ startinsert ]],
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	command = [[%s/\s\+$//e]],
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	command = [[%s/\n\+\%$//e]],
})

vim.api.nvim_create_autocmd("QuitPre", {
	desc = "Automatically close corresponding location list when quitting a window",
	pattern = "*",
	callback = function()
		if vim.bo.filetype ~= "qf" then
			vim.cmd("silent! lclose")
		end
	end,
})

require("indent")
require("mappings")
require("statusline")

local fzf = require("fzf_git")
fzf.setup()

require("lazy_setup")
