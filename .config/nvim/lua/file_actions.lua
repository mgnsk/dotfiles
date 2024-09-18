local M = {}

--- Configure formatter for the current buffer's filetype to run on BufWritePre.
---
---@param formatters string[]
function M.configureFormatBeforeSave(formatters)
	require("conform").formatters_by_ft[vim.bo.filetype] = formatters
end

--- Configure retab for the current buffer's filetype to run on BufWritePre.
function M.configureRetabBeforeSave()
	local filetype = vim.bo.filetype

	vim.api.nvim_create_autocmd("BufWritePre", {
		group = vim.api.nvim_create_augroup(filetype .. "_retab", {}),
		pattern = "*",
		callback = function()
			if vim.bo.filetype == filetype then
				vim.cmd("silent! retab")
			end
		end,
	})
end

--- Configure linters for the current buffer's filetype to run on BufWritePost.
---
---@param linters string[]
function M.configureLintAfterSave(linters)
	local filetype = vim.bo.filetype

	vim.g["neomake_" .. filetype .. "_enabled_makers"] = linters

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup(filetype .. "_lint", {}),
		pattern = "*",
		callback = function()
			if vim.bo.filetype == filetype then
				vim.cmd("Neomake")
			end
		end,
	})
end

return M
