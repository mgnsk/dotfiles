-- location_callback opens all LSP gotos in a new tab
local location_callback = function(_, result, ctx)
	local util = vim.lsp.util

	if result == nil or vim.tbl_isempty(result) then
		require("vim.lsp.log").info(ctx["method"], "No location found")
		return nil
	end

	vim.api.nvim_command("tabnew")

	if vim.islist(result) then
		util.jump_to_location(result[1], "utf-8", false)
	else
		util.jump_to_location(result, "utf-8", false)
	end
end

--- @type LazySpec[]
return {
	{
		"simrat39/symbols-outline.nvim",
		lazy = true,
		init = function()
			vim.keymap.set("n", "<leader>V", function()
				return require("symbols-outline").toggle_outline()
			end, { desc = "Toggle LSP symbols outline tree" })
		end,
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
		init = function()
			vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Goto definition" })
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Goto declaration" })
			vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "List implementations" })
			vim.keymap.set("n", "go", vim.lsp.buf.type_definition, { desc = "Goto definition" })
			vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "List references" })
			vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, { desc = "Hover signature" })
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
			vim.keymap.set("n", "ga", vim.lsp.buf.code_action, { desc = "Code action" })
		end,
		config = function()
			local group = vim.api.nvim_create_augroup("UserLspConfig", {})

			vim.api.nvim_create_autocmd("LspAttach", {
				group = group,
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)

					if client == nil then
						return
					end

					if client.server_capabilities.inlayHintProvider then
						vim.lsp.inlay_hint.enable(true)
					end

					if client.supports_method("textDocument/documentHighlight") then
						local docHighlightGroup = vim.api.nvim_create_augroup("lsp_document_highlight", {})

						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							group = docHighlightGroup,
							buffer = args.buf,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd("CursorMoved", {
							group = docHighlightGroup,
							buffer = args.buf,
							callback = vim.lsp.buf.clear_references,
						})
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
			lsp.ts_ls.setup({
				capabilities = capabilities,
				-- TODO
				-- init_options = {
				-- 	preferences = {
				-- 		includeInlayParameterNameHints = "all",
				-- 		includeInlayParameterNameHintsWhenArgumentMatchesName = true,
				-- 		includeInlayFunctionParameterTypeHints = true,
				-- 		includeInlayVariableTypeHints = true,
				-- 		includeInlayPropertyDeclarationTypeHints = true,
				-- 		includeInlayFunctionLikeReturnTypeHints = true,
				-- 		includeInlayEnumMemberValueHints = true,
				-- 		importModuleSpecifierPreference = "non-relative",
				-- 	},
				-- },
			})
			lsp.html.setup({
				capabilities = capabilities,
			})
			lsp.cssls.setup({
				capabilities = capabilities,
			})
			lsp.tailwindcss.setup({
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
			lsp.jsonnet_ls.setup({
				capabilities = capabilities,
			})
			lsp.docker_compose_language_service.setup({
				capabilities = capabilities,
			})
		end,
	},
}
