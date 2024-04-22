vim.g.mapleader = ","

local map = require("util").map

local function setupEditorMappings()
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
		":let $curdir=expand('%:p:h')<CR>:vsplit<CR>:ter<CR>cd $curdir<CR>",
		{ desc = "Open new terminal window to right" }
	)
	map(
		"n",
		"tt",
		":let $curdir=expand('%:p:h')<CR>:tabnew<CR>:ter<CR>cd $curdir<CR>",
		{ desc = "Open new terminal tab" }
	)
	map("n", "<leader>v", ":vnew<CR>", { desc = "Open new window to right" })
	map("n", "<leader>s", ":new<CR>", { desc = "Open new window to bottom" })
	map("n", "<leader>t", ":tabnew<CR>", { desc = "Open new tab" })
	map("n", "<leader>e", ":Vex %:h<CR>", { desc = "Open file browser in split" })
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
end

local function setupFZFMappings()
	map("n", "<leader>p", function()
		return require("fzf-lua").builtin()
	end, { desc = "FZF builtin" })

	map("n", "<leader>/", function()
		return require("fzf-lua").commands()
	end, { desc = "FZF commands" })

	map("n", "<leader>b", function()
		return require("fzf-lua").buffers()
	end, { desc = "FZF buffers" })

	-- Grep a single pattern.
	map("n", "<leader>g", function()
		return require("fzf-lua").live_grep()
	end, { desc = "FZF live_grep" })

	-- Grep all words separately, including filename.
	map("n", "<leader>a", function()
		return require("fzf-lua").grep_project({ fzf_opts = { ["--nth"] = false } })
	end, { desc = "FZF grep_project" })

	map("n", "<leader>o", function()
		return require("fzf-lua").files()
	end, { desc = "FZF files" })

	map("n", "<leader>T", function()
		return require("fzf-lua").tags()
	end, { desc = "FZF tags" })

	map("n", "<leader>f", function()
		return require("fzf-lua").lsp_document_symbols()
	end, { desc = "FZF lsp_document_symbols" })

	map("n", "<leader>F", function()
		return require("fzf-lua").lsp_live_workspace_symbols()
	end, { desc = "FZF lsp_live_workspace_symbols" })

	map("n", "<leader>G", function()
		return require("fzf-lua").git_bcommits()
	end, { desc = "FZF git_bcommits" })

	map("n", "<leader>H", function()
		return require("fzf-lua").git_commits()
	end, { desc = "FZF git_commits" })
end

local function goto_next()
	if vim.diagnostic.get_next() then
		vim.diagnostic.goto_next()
		return
	end

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local bufnr = vim.api.nvim_get_current_buf()
	local loclist = vim.fn.getloclist(0)
	require("util").sort_loclist(loclist)

	for _, entry in pairs(loclist) do
		if entry.bufnr == bufnr then
			if entry.lnum == row and entry.col > col or entry.lnum > row then
				vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
				return
			end
		end
	end

	vim.api.nvim_echo({ { "No more valid diagnostics or location list items to move to", "WarningMsg" } }, true, {})
end

local function goto_prev()
	if vim.diagnostic.get_prev() then
		vim.diagnostic.goto_prev()
		return
	end

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local bufnr = vim.api.nvim_get_current_buf()
	local loclist = vim.fn.getloclist(0)
	require("util").sort_loclist(loclist)
	require("util").reverse(loclist)

	for _, entry in pairs(loclist) do
		if entry.bufnr == bufnr then
			if entry.lnum == row and entry.col < col or entry.lnum < row then
				vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col })
				return
			end
		end
	end

	vim.api.nvim_echo({ { "No more valid diagnostics or location list items to move to", "WarningMsg" } }, true, {})
end

local function setupLSPMappings()
	map("n", "<leader>V", function()
		return require("symbols-outline").toggle_outline()
	end, { desc = "Toggle LSP symbols outline tree" })

	map("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
	map("n", "L", vim.diagnostic.open_float, { desc = "Hover diagnostic" })
	map("n", "gd", vim.lsp.buf.definition, { desc = "Goto definition" })
	map("n", "gD", vim.lsp.buf.declaration, { desc = "Goto declaration" })
	map("n", "gi", vim.lsp.buf.implementation, { desc = "List implementations" })
	map("n", "go", vim.lsp.buf.type_definition, { desc = "Goto definition" })
	map("n", "gr", vim.lsp.buf.references, { desc = "List references" })
	map("n", "gs", vim.lsp.buf.signature_help, { desc = "Hover signature" })
	map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
	map("n", "ga", vim.lsp.buf.code_action, { desc = "Code action" })
	map("n", "gj", goto_next, { desc = "Goto next diagnostic or location list item in current buffer" })
	map("n", "gk", goto_prev, { desc = "Goto prev diagnostic or location list item in current buffer" })
end

local function setupGitMappings()
	map("n", "gn", function()
		require("gitsigns").next_hunk()
	end, { desc = "Goto next git hunk" })

	map("n", "gp", function()
		require("gitsigns").prev_hunk()
	end, { desc = "Goto prev git hunk" })

	map("n", "<leader>d", function()
		require("gitsigns").diffthis()
	end, { desc = "Git diff" })

	map("n", "B", function()
		require("gitsigns").blame_line()
	end, { desc = "Git blame line" })

	map("n", "<leader>W", ":Gw!<CR>", { desc = "Select the current buffer when resolving git conflicts" })
end

setupEditorMappings()
setupFZFMappings()
setupLSPMappings()
setupGitMappings()
