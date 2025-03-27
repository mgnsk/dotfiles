--- @type vim.lsp.Config
return {
	cmd = { "buf", "beta", "lsp", "--timeout=0", "--log-format=text" },
	filetypes = { "proto" },
	on_attach = function(client, bufnr)
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function()
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end

				vim.lsp.buf.format({ async = false })
			end,
		})
	end,
}
