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
				"folke/neodev.nvim",
				config = function()
					require("neodev").setup({})
				end,
			},
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client ~= nil and client.server_capabilities.inlayHintProvider then
						vim.lsp.inlay_hint.enable(true)
					end
				end,
			})

			vim.lsp.handlers["textDocument/declaration"] = location_callback
			vim.lsp.handlers["textDocument/definition"] = location_callback
			vim.lsp.handlers["textDocument/typeDefinition"] = location_callback
			vim.lsp.handlers["textDocument/implementation"] = location_callback
			vim.lsp.handlers["textDocument/publishDiagnostics"] =
				vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
					update_in_insert = false,
				})

			local lsp = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			lsp.gopls.setup({
				capabilities = capabilities,
				settings = {
					gopls = {
						hints = {
							assignVariableTypes = false,
							compositeLiteralFields = false,
							compositeLiteralTypes = false,
							constantValues = true,
							functionTypeParameters = true,
							parameterNames = false,
							rangeVariableTypes = true,
						},
					},
				},
			})
			lsp.tsserver.setup({
				capabilities = capabilities,
				init_options = {
					preferences = {
						includeInlayParameterNameHints = "all",
						includeInlayParameterNameHintsWhenArgumentMatchesName = true,
						includeInlayFunctionParameterTypeHints = true,
						includeInlayVariableTypeHints = true,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayEnumMemberValueHints = true,
						importModuleSpecifierPreference = "non-relative",
					},
				},
			})
			lsp.html.setup({
				capabilities = capabilities,
			})
			lsp.cssls.setup({
				capabilities = capabilities,
			})
			lsp.bashls.setup({
				capabilities = capabilities,
			})
			lsp.lua_ls.setup({
				capabilities = capabilities,
				settings = {
					Lua = {
						workspace = {
							checkThirdParty = false,
							library = vim.api.nvim_get_runtime_file("", true),
						},
						completion = {
							enable = true,
						},
						hint = {
							enable = false,
							-- arrayIndex = "Disable",
							-- await = true,
							-- paramName = "All",
							-- paramType = true,
							-- semicolon = "SameLine",
							-- setType = false,
						},
						runtime = { version = "LuaJIT" },
						diagnostics = { globals = { "vim" } },
						telemetry = { enable = false },
					},
				},
			})
			lsp.phpactor.setup({
				capabilities = capabilities,
				-- TODO
				-- init_options = {
				-- 	["language_server_worse_reflection.inlay_hints.enable"] = true,
				-- 	["language_server_worse_reflection.inlay_hints.params"] = true,
				-- 	["language_server_worse_reflection.inlay_hints.types"] = true,
				-- },
			})
			lsp.rust_analyzer.setup({
				capabilities = capabilities,
			})
		end,
	},
}
