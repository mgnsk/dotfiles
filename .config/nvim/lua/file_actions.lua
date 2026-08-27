local M = {}

--- Register a custom formatter. The formatter name is config.command.
---
---@param name string
---@param config conform.FormatterConfigOverride
function M.registerFormatter(name, config)
	if require("util").in_diff_mode() then
		return
	end

	require("conform").formatters[name] = config
end

--- Configure biome LSP or prettier formatter.
function M.configureBiomeOrPrettierFormatBeforeSave()
	local function configure_format()
		local has_biome = false

		for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
			if client.name == "biome" then
				has_biome = true
				break
			end
		end

		if has_biome then
			M.configureFormatBeforeSave({ lsp_format = "fallback" })
		else
			M.configureFormatBeforeSave({ "prettier" })
		end
	end

	configure_format()
	vim.api.nvim_create_autocmd("LspAttach", { buffer = 0, callback = configure_format })
end

--- Configure formatter for the current buffer's filetype to run on BufWritePre.
---
---@param formatters string[]
function M.configureFormatBeforeSave(formatters)
	if require("util").in_diff_mode() then
		return
	end

	require("conform").formatters_by_ft[vim.bo.filetype] = formatters
end

--- Configure retab for the current buffer's filetype to run on BufWritePre.
function M.configureRetabBeforeSave()
	if require("util").in_diff_mode() then
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

--- Configure linters for the current buffer's filetype to run on BufWritePost.
---
---@param linters string[]
function M.configureLintAfterSave(linters)
	if require("util").in_diff_mode() then
		return
	end

	local filetype = vim.bo.filetype

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup(filetype .. "_lint", {}),
		pattern = "*",
		callback = function()
			if vim.bo.filetype == filetype then
				require("lint").try_lint(linters)
			end
		end,
	})
end

return M
