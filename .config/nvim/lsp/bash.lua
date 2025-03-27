--- @type vim.lsp.Config
return {
	cmd = { "bash-language-server", "start" },
	filetypes = { "bash", "sh" },
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
