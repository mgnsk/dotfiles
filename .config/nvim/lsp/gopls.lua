--- @type vim.lsp.Config
return {
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
