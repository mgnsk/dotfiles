vim.g.mapleader = ","

local map = require("util").map

map("v", "Y", [["+y<CR>]], { desc = "Big yank (system clipboard)" })
map("i", "jj", "<Esc>", { desc = "Escape from insert mode" })
map("t", "jj", [[<C-\><C-n>]], { desc = "Escape from terminal mode" })
map("t", "<Esc>", [[<C-\><C-n>]], { desc = "Escape from terminal mode" })
map("n", "<Esc><Esc>", ":nohlsearch<CR>", { desc = "Clear search highlight" })

map("n", "qq", function()
	vim.cmd("q")
end, { desc = "Quit buffer" })

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
	":let $curdir=expand('%:p:h')<CR>:vsplit<CR>:ter<CR>cd $curdir<CR>",
	{ desc = "Open new terminal window to right" }
)
map("n", "tt", ":let $curdir=expand('%:p:h')<CR>:tabnew<CR>:ter<CR>cd $curdir<CR>", { desc = "Open new terminal tab" })
map("n", "<leader>v", ":vnew<CR>", { desc = "Open new window to right" })
map("n", "<leader>s", ":new<CR>", { desc = "Open new window to bottom" })
map("n", "<leader>t", ":tabnew<CR>", { desc = "Open new tab" })
map("n", "<leader>e", ":Tex<CR>", { desc = "Open file browser in new tab" })
map("n", "<leader>j", ":bnext<CR>", { desc = "Switch to next buffer" })
map("n", "<leader>k", ":bprev<CR>", { desc = "Switch to previous buffer" })
map("n", "<leader>u", "gg=G``", { desc = "Indent buffer" })
map("n", "<leader>w", ":set wrap!<CR>", { desc = "Toggle word wrap" })

map("n", "<leader>B", ":Git blame<CR>", { desc = "Git blame" })
map("n", "<leader>W", ":Gw!<CR>", { desc = "Select the current buffer when resolving git conflicts" })

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
