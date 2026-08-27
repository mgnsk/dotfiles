if require("util").in_diff_mode() then
	return
end

-- location_callback opens all LSP gotos in a new tab
---@param options vim.lsp.LocationOpts.OnList
local location_callback = function(options)
	if vim.tbl_isempty(options.items) then
		vim.lsp.log.info(options.context.method, "No location found")
		return nil
	end

	vim.api.nvim_command("tabnew")
	vim.lsp.util.show_document(options.items[1].user_data, "utf-8", { reuse_win = false, focus = true })
end

vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, { desc = "Hover signature" })

vim.keymap.set("n", "gd", function()
	vim.lsp.buf.definition({
		on_list = location_callback,
	})
end, { desc = "Goto definition" })

vim.keymap.set("n", "gD", function()
	vim.lsp.buf.declaration({
		on_list = location_callback,
	})
end, { desc = "Goto declaration" })

vim.keymap.set("n", "go", function()
	vim.lsp.buf.type_definition({
		on_list = location_callback,
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

vim.keymap.set("n", "ga", function()
	return require("fzf-lua").lsp_code_actions()
end, { desc = "Code actions" })

vim.api.nvim_create_user_command("InlayHintDisable", function()
	vim.lsp.inlay_hint.enable(false)
end, { desc = "Disable inlay hints" })

vim.api.nvim_create_user_command("InlayHintEnable", function()
	vim.lsp.inlay_hint.enable(true)
end, { desc = "Enable inlay hints" })

local group = vim.api.nvim_create_augroup("UserLspConfig", {})

vim.api.nvim_create_autocmd("LspAttach", {
	group = group,
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)

		if client == nil then
			return
		end

		-- if client.server_capabilities.inlayHintProvider then
		-- 	vim.lsp.inlay_hint.enable(true)
		-- end

		if client.server_capabilities.documentHighlightProvider then
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

vim.schedule(function()
	vim.lsp.config("*", {
		capabilities = require("blink.cmp").get_lsp_capabilities(),
	})

	vim.lsp.config("biome", {
		root_dir = function(bufnr, on_dir)
			local root = vim.fs.root(bufnr, { "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc" })
			if root then
				on_dir(root)
			end
		end,
	})

	vim.lsp.enable({
		"luals",
		"gopls",
		"tsgo",
		"biome", -- TODO: use as formatter
		"bashls",
		"phpactor",
		"jsonnet_ls",
		"buf_ls",
		"nil_ls",
		"helm_ls",
		"ty",
		"yamlls",
		"ansiblels",
	})

	-- vim.lsp.enable()'s own retroactive-attach check (v:vim_did_enter /
	-- did_filetype()) is only true synchronously right after a buffer opens,
	-- so by the time this scheduled callback runs it's gone stale for the
	-- file opened from the command line. Re-fire the same targeted autocmd
	-- group it uses internally to attach to already-open buffers.
	vim.cmd.doautoall("nvim.lsp.enable FileType")
end)
