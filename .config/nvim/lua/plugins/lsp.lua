-- location_callback opens all LSP gotos in a new tab
local goto_callback = function(_, result, ctx)
	local util = vim.lsp.util

	if result == nil or vim.tbl_isempty(result) then
		require("vim.lsp.log").info(ctx["method"], "No location found")
		return nil
	end

	if vim.islist(result) then
		if #result > 0 then
			-- Take the first result.
			vim.api.nvim_command("tabnew")
			util.show_document(result[1], "utf-8", { reuse_win = false, focus = true })
		end
	else
		vim.api.nvim_command("tabnew")
		util.show_document(result, "utf-8", { reuse_win = false, focus = true })
	end
end

local function organize_go_imports(client, bufnr)
	local params = vim.lsp.util.make_range_params(nil, vim.lsp.util._get_offset_encoding(0))
	params.context = { only = { "source.organizeImports" } }

	local resp = client.request_sync("textDocument/codeAction", params, 3000, bufnr)
	for _, r in pairs(resp and resp.result or {}) do
		if r.edit then
			vim.lsp.util.apply_workspace_edit(r.edit, vim.lsp.util._get_offset_encoding(0))
		else
			print(r.command)
			vim.lsp.buf.execute_command(r.command)
		end
	end
end

--- @type LazySpec[]
return {
	{
		"Bilal2453/luvit-meta", -- optional `vim.uv` typings
		dir = vim.fn.stdpath("config") .. "/plugins/luvit-meta",
		-- ft = "lua",
	},
	{
		"neovim/nvim-lspconfig",
		dir = vim.fn.stdpath("config") .. "/plugins/nvim-lspconfig",
		cond = not os.getenv("NVIM_DIFF"),
		event = "VeryLazy",
		init = function()
			vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
			vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, { desc = "Hover signature" })

			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Goto definition" })
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Goto declaration" })
			vim.keymap.set("n", "go", vim.lsp.buf.type_definition, { desc = "Goto type definition" })

			vim.keymap.set("n", "gi", function()
				return require("fzf-lua").lsp_implementations()
			end, { desc = "List implementations" })

			vim.keymap.set("n", "gr", function()
				-- TODO: go: include dependencies
				return require("fzf-lua").lsp_references()
			end, { desc = "List references" })

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

			--- Open gotos in new tab.
			vim.lsp.handlers["textDocument/declaration"] = goto_callback
			vim.lsp.handlers["textDocument/definition"] = goto_callback
			vim.lsp.handlers["textDocument/typeDefinition"] = goto_callback

			vim.lsp.handlers["textDocument/publishDiagnostics"] =
				vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
					update_in_insert = false,
				})

			local lsp = require("lspconfig")
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			lsp.gopls.setup({
				on_attach = function(client, bufnr)
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = bufnr,
						callback = function()
							if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
								return
							end

							organize_go_imports(client, bufnr)
							require("conform").format({ lsp_fallback = true })
						end,
					})
				end,
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
			lsp.bashls.setup({
				capabilities = capabilities,
			})
			lsp.lua_ls.setup({
				cmd = { "lua-language-server", "--force-accept-workspace" },
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
				on_attach = function(client, bufnr)
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = bufnr,
						callback = function()
							if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
								return
							end

							require("conform").format({ lsp_fallback = true })
						end,
					})
				end,
				capabilities = capabilities,
			})
			lsp.jsonnet_ls.setup({
				capabilities = capabilities,
			})
			lsp.docker_compose_language_service.setup({
				capabilities = capabilities,
			})
			lsp.buf_ls.setup({
				capabilities = capabilities,
			})
			lsp.nil_ls.setup({
				capabilities = capabilities,
			})
		end,
	},
}
