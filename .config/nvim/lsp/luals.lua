--- @type vim.lsp.Config
return {
	cmd = { "lua-language-server", "--force-accept-workspace" },
	filetypes = { "lua" },
	root_dir = function(bufnr, on_dir)
		local config_dir = vim.fn.stdpath("config")
		local fname = vim.api.nvim_buf_get_name(bufnr)

		if vim.startswith(fname, config_dir .. "/") then
			on_dir(config_dir)
			return
		end

		on_dir(vim.fs.root(bufnr, { ".luarc.json", ".luarc.jsonc", ".git" }) or vim.fn.getcwd())
	end,
	settings = {
		Lua = {
			workspace = {
				checkThirdParty = false,
				library = { vim.env.VIMRUNTIME },
			},
			completion = {
				enable = true,
			},
			hint = {
				enable = true,
				arrayIndex = "Disable",
				await = true,
				paramName = "All",
				paramType = true,
				semicolon = "SameLine",
				setType = true,
			},
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim" } },
			telemetry = { enable = false },
		},
	},
}
