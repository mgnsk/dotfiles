---@param client vim.lsp.Client
---@param bufnr integer
local function organize_go_imports(client, bufnr)
	local params = vim.lsp.util.make_range_params(nil, client.offset_encoding)
	params.context = { only = { "source.organizeImports" } }

	local resp = client:request_sync("textDocument/codeAction", params, 3000, bufnr)
	for _, r in pairs(resp and resp.result or {}) do
		if r.edit then
			vim.lsp.util.apply_workspace_edit(r.edit, client.offset_encoding)
		else
			print(r.command)
			vim.lsp.buf.execute_command(r.command)
		end
	end
end

--- @type vim.lsp.Config
return {
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	root_markers = { "go.mod" },
	on_attach = function(client, bufnr)
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function()
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end

				organize_go_imports(client, bufnr)
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
