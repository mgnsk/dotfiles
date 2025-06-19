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

		if client:supports_method("textDocument/documentHighlight") then
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				buffer = args.buf,
				callback = vim.lsp.buf.document_highlight,
			})

			vim.api.nvim_create_autocmd("CursorMoved", {
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

vim.lsp.enable({
	"luals",
	"gopls",
	"ts_ls",
	"html",
	"css",
	-- "bash",
	"phpactor",
	"rust_analyzer",
	"jsonnet_ls",
	"docker_compose_language_service",
	"buf_ls",
	"nil_ls",
	"ansiblels",
})
