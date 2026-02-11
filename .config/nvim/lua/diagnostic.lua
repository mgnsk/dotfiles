vim.diagnostic.config({
	update_in_insert = false,
	virtual_text = true,
})

local diagnostics_group = vim.api.nvim_create_augroup("diagnostics", {})

vim.api.nvim_create_autocmd({ "DiagnosticChanged", "InsertLeave" }, {
	desc = "Automatically hide/show and update loclist",
	group = diagnostics_group,
	callback = function()
		if vim.fn.mode() == "i" then
			-- Don't update in insert mode.
			return
		end

		vim.schedule(function()
			local winid = vim.api.nvim_get_current_win()

			-- Save main window view to avoid jumping.
			local view = vim.api.nvim_win_call(winid, function()
				return vim.fn.winsaveview()
			end)

			pcall(vim.diagnostic.setloclist, { winnr = winid, open = true })

			-- Limit loclist height.
			local loclist = vim.fn.getloclist(winid, { winid = winid })
			if loclist and loclist.winid > 0 then
				local num_items = #vim.fn.getloclist(winid)
				local max_h = 5
				vim.api.nvim_win_set_height(loclist.winid, math.min(num_items, max_h))
				-- Forces redraw of loclist (avoids empty lines).
				vim.api.nvim_win_set_cursor(loclist.winid, { 1, 0 })
			end

			vim.api.nvim_set_current_win(winid)

			-- Restore main windows view.
			vim.api.nvim_win_call(winid, function()
				vim.fn.winrestview(view)
			end)
		end)
	end,
})

vim.api.nvim_create_autocmd("QuitPre", {
	desc = "Automatically close corresponding location list when quitting a window",
	group = diagnostics_group,
	callback = function()
		if vim.bo.filetype ~= "qf" then
			vim.cmd("silent! lclose")
		end
	end,
})

vim.keymap.set("n", "U", vim.diagnostic.open_float, { desc = "Hover diagnostic" })
vim.keymap.set("n", "gj", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Goto next diagnostic in current buffer" })
vim.keymap.set("n", "gk", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Goto prev diagnostic in current buffer" })
