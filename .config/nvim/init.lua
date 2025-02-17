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

function _G.get_fold_expr(lnum)
	local ok, result = pcall(vim.treesitter.foldexpr, lnum)
	if not ok then
		return "0"
	end

	return result
end

vim.api.nvim_create_autocmd("BufReadPost", {
	-- Important to schedule this function for performance.
	callback = vim.schedule_wrap(function()
		vim.opt.foldmethod = "expr"
		vim.wo.foldexpr = "v:lua.get_fold_expr()"
		vim.opt.foldnestmax = 3
		vim.opt.foldlevel = 99
		vim.opt.foldlevelstart = 99
	end),
})

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
vim.keymap.set("n", "-", ":Oil<CR>", { desc = "Open Oil file browser" })
vim.keymap.set(
	"n",
	"<leader>e",
	":let $curdir=expand('%:p:h')<CR>:tabnew<CR>:e $curdir<CR>",
	{ desc = "Open netrw file browser in tab" }
)
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

vim.keymap.set("n", "<leader>l", function()
	if vim.wo.scrolloff > 0 then
		vim.wo.scrolloff = 0
	else
		vim.wo.scrolloff = 999
	end
end, { desc = "Toggle cursor lock" })

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

vim.keymap.set("n", "<leader>S", function()
	if vim.o.spell then
		vim.o.spell = false
		print("spell off")
	else
		vim.o.spell = true
		print("spell on")
	end
end, { desc = "Toggle vim spell check" })

vim.api.nvim_create_user_command("GhBrowse", function()
	local file = vim.fn.expand("%")
	if string.len(file) == 0 then
		return
	end

	vim.fn.system(string.format("gh browse %s --branch $(git rev-parse --abbrev-ref HEAD)", file))
end, { desc = "Browse current file on Github" })

require("diagnostic")
require("statusline")
require("lazy_setup")
