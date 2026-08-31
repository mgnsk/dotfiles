-- Nix installs plugins as a single packpath entry
-- (`pack/*/start/<hash>-vimplugin-<name>/`) whose store hash changes on every
-- rebuild, so discover plugin dirs from packpath at startup rather than
-- hardcoding a path.
--- @return string[]
local function plugin_library()
	local dirs = {}

	for _, packpath in ipairs(vim.opt.packpath:get()) do
		for _, dir in ipairs(vim.fn.glob(packpath .. "/pack/*/start/*", true, true)) do
			if vim.fn.isdirectory(dir .. "/lua") == 1 then
				table.insert(dirs, dir)
			end
		end
	end

	return dirs
end

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
				library = vim.list_extend({ vim.env.VIMRUNTIME }, plugin_library()),
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
