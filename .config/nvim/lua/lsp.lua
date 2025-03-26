-- location_callback opens all LSP gotos in a new tab
local goto_callback = function(_, result, ctx)
	local util = vim.lsp.util

	if result == nil or vim.tbl_isempty(result) then
		vim.lsp.log.info(ctx["method"], "No location found")
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

--- Adapter for nightly neovim. TOOD: clean up and combine this with goto_callback.
---@param options vim.lsp.LocationOpts.OnList
local goto_callback_adapter = function(options)
	local result = {}
	for _, item in ipairs(options.items) do
		table.insert(result, item.user_data)
	end
	goto_callback(nil, result, options.context)
end

vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, { desc = "Hover signature" })

vim.keymap.set("n", "gd", function()
	vim.lsp.buf.definition({
		on_list = goto_callback_adapter,
	})
end, { desc = "Goto definition" })

vim.keymap.set("n", "gD", function()
	vim.lsp.buf.declaration({
		on_list = goto_callback_adapter,
	})
end, { desc = "Goto declaration" })

vim.keymap.set("n", "go", function()
	vim.lsp.buf.type_definition({
		on_list = goto_callback_adapter,
	})
end, { desc = "Goto type definition" })

vim.keymap.set("n", "gi", function()
	return require("fzf-lua").lsp_implementations()
end, { desc = "List implementations" })

vim.keymap.set("n", "gr", function()
	-- TODO: go: include dependencies
	return require("fzf-lua").lsp_references()
end, { desc = "List references" })

vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
vim.keymap.set("n", "ga", vim.lsp.buf.code_action, { desc = "Code action" })

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

-- vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
-- 	update_in_insert = false,
-- })

local capabilities = require("blink.cmp").get_lsp_capabilities()

vim.lsp.config("*", {
	capabilities = capabilities,
	root_markers = { ".git" },
})

vim.lsp.config["luals"] = {
	cmd = { "lua-language-server", "--force-accept-workspace" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc" },
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
}
vim.lsp.enable("luals")

vim.lsp.config["gopls"] = {
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	on_attach = function(client, bufnr)
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function()
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end

				local function organize_go_imports()
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

				organize_go_imports(client, bufnr)
				vim.lsp.buf.format({ async = false })
			end,
		})
	end,
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
}
vim.lsp.enable("gopls")

vim.lsp.config["ts_ls"] = {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
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
}
vim.lsp.enable("ts_ls")

vim.lsp.config["html"] = {
	cmd = { "vscode-html-language-server", "--stdio" },
	filetypes = { "html" },
}
vim.lsp.enable("html")

vim.lsp.config["css"] = {
	cmd = { "vscode-css-language-server", "--stdio" },
	filetypes = { "css", "scss", "less" },
}
vim.lsp.enable("css")

vim.lsp.config["bash"] = {
	cmd = { "bash-language-server", "start" },
	filetypes = { "bash", "sh" },
}
vim.lsp.enable("bash")

vim.lsp.config["phpactor"] = {
	cmd = { "phpactor", "language-server" },
	filetypes = { "php" },
	-- TODO
	-- init_options = {
	-- 	["language_server_worse_reflection.inlay_hints.enable"] = true,
	-- 	["language_server_worse_reflection.inlay_hints.params"] = true,
	-- 	["language_server_worse_reflection.inlay_hints.types"] = true,
	-- },
}
vim.lsp.enable("phpactor")

vim.lsp.config["rust_analyzer"] = {
	cmd = { "rust-analyzer" },
	filetypes = { "rust" },
	on_attach = function(_, bufnr)
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
}
vim.lsp.enable("rust_analyzer")

vim.lsp.config["jsonnet_ls"] = {
	cmd = { "jsonnet-language-server" },
	filetypes = { "jsonnet", "libsonnet" },
}
vim.lsp.enable("jsonnet_ls")

vim.lsp.config["docker_compose_language_service"] = {
	cmd = { "docker-compose-langserver", "--stdio" },
	filetypes = { "yaml.docker-compose" },
}
vim.lsp.enable("docker_compose_language_service")

vim.lsp.config["buf_ls"] = {
	cmd = { "buf", "beta", "lsp", "--timeout=0", "--log-format=text" },
	filetypes = { "proto" },
}
vim.lsp.enable("buf_ls")

vim.lsp.config["nil_ls"] = {
	cmd = { "nil" },
	filetypes = { "nix" },
}
vim.lsp.enable("nil_ls")
