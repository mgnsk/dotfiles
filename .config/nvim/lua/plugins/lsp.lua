-- location_callback opens all LSP gotos in a new tab
local location_callback = function(_, result, ctx)
	local util = vim.lsp.util

	if result == nil or vim.tbl_isempty(result) then
		require("vim.lsp.log").info(ctx["method"], "No location found")
		return nil
	end

	vim.api.nvim_command("tabnew")

	if vim.tbl_islist(result) then
		util.jump_to_location(result[1], "utf-8", false)
		if #result > 1 then
			vim.diagnostic.setqflist(util.locations_to_items(result, "utf-8"))
			vim.api.nvim_command("copen")
			vim.api.nvim_command("wincmd p")
		end
	else
		util.jump_to_location(result, "utf-8", false)
	end
end

return {
	{
		"simrat39/symbols-outline.nvim",
		lazy = true,
		config = function()
			require("symbols-outline").setup()
		end,
	},
	{
		"neovim/nvim-lspconfig",
		cond = not os.getenv("NVIM_DIFF"),
		event = { "BufEnter" },
		dependencies = {
			{
				"ray-x/lsp_signature.nvim",
				config = function()
					require("lsp_signature").setup({})
				end,
			},
			{
				"folke/neodev.nvim",
				config = function()
					require("neodev").setup({})
				end,
			},
		},
		init = function()
			vim.lsp.handlers["textDocument/declaration"] = location_callback
			vim.lsp.handlers["textDocument/definition"] = location_callback
			vim.lsp.handlers["textDocument/typeDefinition"] = location_callback
			vim.lsp.handlers["textDocument/implementation"] = location_callback
			vim.lsp.handlers["textDocument/publishDiagnostics"] =
				vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
					update_in_insert = false,
				})
		end,
		config = function()
			local lsp = require("lspconfig")

			lsp.util.default_config = vim.tbl_deep_extend("force", lsp.util.default_config, {
				capabilities = require("cmp_nvim_lsp").default_capabilities(),
				on_init = function(client, bufnr)
					client.server_capabilities.semanticTokensProvider = nil
				end,
			})

			lsp.gopls.setup({})
			lsp.tsserver.setup({})
			lsp.html.setup({})
			lsp.cssls.setup({})
			lsp.bashls.setup({})
			lsp.lua_ls.setup({
				settings = {
					Lua = {
						workspace = {
							checkThirdParty = false,
							library = vim.api.nvim_get_runtime_file("", true),
						},
						completion = {
							enable = true,
						},
						runtime = { version = "LuaJIT" },
						diagnostics = { globals = { "vim" } },
						telemetry = { enable = false },
					},
				},
			})
			lsp.phpactor.setup({})
			lsp.svelte.setup({})
		end,
	},
}
