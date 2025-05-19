local M = {}

--- Create a neomake-safe filetype string.
---
---@param ft string
---@return string
local function neomake_filetype(ft)
	local result = string.gsub(ft, "%.", "_")
	return result
end

--- Register a custom formatter. The formatter name is config.command.
---
---@param config conform.FormatterConfigOverride
function M.registerFormatter(config)
	if os.getenv("NVIM_DIFF") then
		return
	end

	require("conform").formatters[config.command] = config
end

--- Configure formatter for the current buffer's filetype to run on BufWritePre.
---
---@param formatters string[]
function M.configureFormatBeforeSave(formatters)
	if os.getenv("NVIM_DIFF") then
		return
	end

	require("conform").formatters_by_ft[vim.bo.filetype] = formatters
end

--- Configure retab for the current buffer's filetype to run on BufWritePre.
function M.configureRetabBeforeSave()
	if os.getenv("NVIM_DIFF") then
		return
	end

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

---@class (exact) NeomakeLinter
---@field exe string
---@field args string[]
---@field errorformat string

--- Register a custom linter for the current buffer's filetype.
---
---@param config NeomakeLinter
function M.registerLinter(config)
	if os.getenv("NVIM_DIFF") then
		return
	end

	vim.g["neomake_" .. neomake_filetype(vim.bo.filetype) .. "_" .. config.exe .. "_maker"] = config
end

--- Configure linters for the current buffer's filetype to run on BufWritePost.
---
---@param linters string[]
function M.configureLintAfterSave(linters)
	if os.getenv("NVIM_DIFF") then
		return
	end

	vim.g["neomake_" .. neomake_filetype(vim.bo.filetype) .. "_enabled_makers"] = linters

	local filetype = vim.bo.filetype

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
