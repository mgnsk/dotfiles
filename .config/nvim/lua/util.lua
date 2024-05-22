local M = {}

function M.buf_size(buf)
	return vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
end

function M.map(mode, lhs, rhs, opts_overrides)
	local opts = {
		noremap = true,
		silent = true,
	}
	opts = vim.tbl_extend("force", opts, opts_overrides or {})
	vim.keymap.set(mode, lhs, rhs, opts)
end

function M.reverse(t)
	for i = 1, math.floor(#t / 2) do
		local j = #t - i + 1
		t[i], t[j] = t[j], t[i]
	end
end

function M.sort_loclist(loclist)
	table.sort(loclist, function(a, b)
		if a.lnum < b.lnum then
			return true
		elseif a.lnum > b.lnum then
			return false
		end

		return a.col < b.col
	end)
end

function M.goto_next()
	if vim.diagnostic.get_next() then
		vim.diagnostic.goto_next()
		return
	end

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local bufnr = vim.api.nvim_get_current_buf()
	local loclist = vim.fn.getloclist(0)
	M.sort_loclist(loclist)

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

function M.goto_prev()
	if vim.diagnostic.get_prev() then
		vim.diagnostic.goto_prev()
		return
	end

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local bufnr = vim.api.nvim_get_current_buf()
	local loclist = vim.fn.getloclist(0)
	M.sort_loclist(loclist)
	M.reverse(loclist)

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

return M
