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

vim.o.autoindent = true
vim.o.smartindent = true
vim.o.expandtab = false
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.tabstop = 4
vim.cmd("filetype plugin indent on")

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

local map = require("util").map

vim.g.mapleader = ","

vim.g.clipboard = {
	name = "OSC 52",
	copy = {
		["+"] = require("vim.ui.clipboard.osc52").copy("+"),
		["*"] = require("vim.ui.clipboard.osc52").copy("*"),
	},
	paste = {
		["+"] = require("vim.ui.clipboard.osc52").paste("+"),
		["*"] = require("vim.ui.clipboard.osc52").paste("*"),
	},
}

map("v", "Y", [["+y<CR>]], { desc = "Big yank (system clipboard)" })
map("i", "jj", "<Esc>", { desc = "Escape from insert mode" })
map("t", "jj", [[<C-\><C-n>]], { desc = "Escape from terminal mode" })
map("t", "<Esc>", [[<C-\><C-n>]], { desc = "Escape from terminal mode" })
map("n", "<Esc><Esc>", ":nohlsearch<CR>", { desc = "Clear search highlight" })

map("n", "qq", function()
	vim.cmd("q!")
end, { desc = "Quit window" })

map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

map("n", "H", "gT", { desc = "Switch to previous tab" })
map("n", "L", "gt", { desc = "Switch to next tab" })

map("n", "<leader>.", ":", { desc = "Command mode", silent = false })
map(
	"n",
	"<leader>,",
	":let $curdir=substitute(expand('%:p:h'), 'oil://', '', '')<CR>:vsplit<CR>:ter<CR>cd $curdir<CR>",
	{ desc = "Open new terminal window to right in current buffer's directory" }
)
map(
	"n",
	"tt",
	":let $curdir=substitute(expand('%:p:h'), 'oil://', '', '')<CR>:tabnew<CR>:ter<CR>cd $curdir<CR>",
	{ desc = "Open new terminal tab in current buffer's directory" }
)
map("n", "<leader>v", ":vnew<CR>", { desc = "Open new window to right" })
map("n", "<leader>s", ":new<CR>", { desc = "Open new window to bottom" })
map("n", "<leader>t", ":tabnew<CR>", { desc = "Open new tab" })
map("n", "<leader>e", ":let $curdir=expand('%:h')<CR>:tabnew<CR>:e $curdir<CR>", { desc = "Open file browser in tab" })
map("n", "<leader>j", ":bnext<CR>", { desc = "Switch to next buffer" })
map("n", "<leader>k", ":bprev<CR>", { desc = "Switch to previous buffer" })
map("n", "<leader>u", "gg=G``", { desc = "Indent buffer" })
map("n", "<leader>w", ":set wrap!<CR>", { desc = "Toggle word wrap" })

map("n", "<leader>l", function()
	if vim.wo.scrolloff > 0 then
		vim.wo.scrolloff = 0
	else
		vim.wo.scrolloff = 999
	end
end, { desc = "Toggle cursor lock" })

map("n", "<leader>mt", ":tabm +1<CR>", { desc = "Move tab to right" })
map("n", "<leader>mT", ":tabm -1<CR>", { desc = "Move tab to left" })

for i = 1, 9 do
	map("n", string.format("<leader>%d", i), string.format("%dgt", i), { desc = string.format("Goto %dth tab", i) })
end
map("n", "<leader>0", ":tablast<CR>", { desc = "Goto last tab" })

map("n", "<leader>S", function()
	if vim.o.spell then
		vim.o.spell = false
		print("spell off")
	else
		vim.o.spell = true
		print("spell on")
	end
end, { desc = "Toggle vim spell check" })

map("n", "<leader>U", ":UndotreeToggle<CR>", { desc = "Toggle undo tree" })

map("n", "gj", require("util").goto_next, { desc = "Goto next diagnostic or location list item in current buffer" })
map("n", "gk", require("util").goto_prev, { desc = "Goto prev diagnostic or location list item in current buffer" })

require("statusline")
require("lazy_setup")
