vim.diagnostic.config({
	update_in_insert = false,
})

local diagnostics_group = vim.api.nvim_create_augroup("diagnostics", {})

vim.api.nvim_create_autocmd("QuitPre", {
	desc = "Automatically close corresponding location list when quitting a window",
	group = diagnostics_group,
	callback = function()
		if vim.bo.filetype ~= "qf" then
			vim.cmd("silent! lclose")
		end
	end,
})

local function reverse(t)
	for i = 1, math.floor(#t / 2) do
		local j = #t - i + 1
		t[i], t[j] = t[j], t[i]
	end
end

local function sort_loclist(loclist)
	table.sort(loclist, function(a, b)
		if a.lnum < b.lnum then
			return true
		elseif a.lnum > b.lnum then
			return false
		end

		return a.col < b.col
	end)
end

local function goto_next()
	if vim.diagnostic.get_next() then
		vim.diagnostic.goto_next()
		return
	end

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local bufnr = vim.api.nvim_get_current_buf()
	local loclist = vim.fn.getloclist(0)
	sort_loclist(loclist)

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
	sort_loclist(loclist)
	reverse(loclist)

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

vim.keymap.set("n", "U", vim.diagnostic.open_float, { desc = "Hover diagnostic" })
vim.keymap.set("n", "gj", goto_next, { desc = "Goto next diagnostic or location list item in current buffer" })
vim.keymap.set("n", "gk", goto_prev, { desc = "Goto prev diagnostic or location list item in current buffer" })
