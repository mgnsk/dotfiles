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
vim.o.wrap = true
vim.o.inccommand = "split"
vim.o.encoding = "UTF-8"
vim.o.path = vim.o.path .. "**"

vim.o.autoindent = true
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

vim.api.nvim_create_autocmd("TermOpen", {
	command = [[ startinsert ]],
})

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

vim.keymap.set("v", "Y", [["+y<CR><Up>]], { desc = "Big yank (system clipboard)" })
vim.keymap.set("i", "jj", "<Esc>", { desc = "Escape from insert mode" })
vim.keymap.set("t", "jj", [[<C-\><C-n>]], { desc = "Escape from terminal mode" })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Escape from terminal mode" })
vim.keymap.set("n", "<Esc><Esc>", ":nohlsearch<CR>", { desc = "Clear search highlight" })

vim.keymap.set("n", "qq", function()
	vim.cmd("q!")
end, { desc = "Quit window" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

vim.keymap.set("n", "H", "gT", { desc = "Switch to previous tab" })
vim.keymap.set("n", "L", "gt", { desc = "Switch to next tab" })

vim.keymap.set("n", "<leader>.", ":", { desc = "Command mode" })
vim.keymap.set(
	"n",
	"<leader>,",
	":let $curdir=substitute(expand('%:p:h'), 'oil://', '', '')<CR>:vsplit<CR>:ter<CR>cd $curdir<CR>",
	{ desc = "Open new terminal window to right in current buffer's directory" }
)
vim.keymap.set(
	"n",
	"tt",
	":let $curdir=substitute(expand('%:p:h'), 'oil://', '', '')<CR>:tabnew<CR>:ter<CR>cd $curdir<CR>",
	{ desc = "Open new terminal tab in current buffer's directory" }
)
vim.keymap.set("n", "<leader>v", ":vnew<CR>", { desc = "Open new window to right" })
vim.keymap.set("n", "<leader>s", ":new<CR>", { desc = "Open new window to bottom" })
vim.keymap.set("n", "<leader>t", ":tabnew<CR>", { desc = "Open new tab" })
vim.keymap.set("n", "<leader>j", ":bnext<CR>", { desc = "Switch to next buffer" })
vim.keymap.set("n", "<leader>k", ":bprev<CR>", { desc = "Switch to previous buffer" })
vim.keymap.set("n", "<leader>u", "gg=G``", { desc = "Indent buffer" })
vim.keymap.set("n", "<leader>w", ":set wrap!<CR>", { desc = "Toggle word wrap" })

vim.keymap.set(
	"n",
	"<leader>D",
	[[:let b = bufnr("%") | vnew | execute 'buffer' b<CR>]],
	{ silent = true, desc = "Duplicate current buffer to a new vertical window" }
)

vim.keymap.set(
	"n",
	"<leader>T",
	[[:let b = bufnr("%") | tabnew | execute 'buffer' b<CR>]],
	{ silent = true, desc = "Duplicate current buffer to a new tab" }
)

vim.keymap.set("n", "<leader>mt", ":tabm +1<CR>", { desc = "Move tab to right" })
vim.keymap.set("n", "<leader>mT", ":tabm -1<CR>", { desc = "Move tab to left" })

for i = 1, 9 do
	vim.keymap.set(
		"n",
		string.format("<leader>%d", i),
		string.format("%dgt", i),
		{ desc = string.format("Goto %dth tab", i) }
	)
end
vim.keymap.set("n", "<leader>0", ":tablast<CR>", { desc = "Goto last tab" })

vim.cmd("packloadall")

require("autotabline").setup()
require("colors")
require("completion")
require("diagnostic")
require("dumb-autopairs").setup()
require("filemanager")
require("formatting")
require("fzf")
require("git")
require("linting")
require("lsp")
require("statusline")
require("treesitter")
require("undo")
