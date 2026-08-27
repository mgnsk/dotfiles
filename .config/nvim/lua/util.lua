local M = {}

local function git_show_in_new_buf(commit)
	local output = vim.fn.systemlist("git show " .. commit)
	vim.cmd.tabnew()
	vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.modifiable = false
	vim.bo.filetype = "git"
end

--- Whether Neovim is running as a diff-viewer helper (e.g. git difftool),
--- in which case interactive-only setup (LSP, formatters, linters,
--- completion) should be skipped.
local function in_diff_mode()
	return os.getenv("NVIM_DIFF") ~= nil
end

M.treesitter_max_filesize = 256 * 1024
M.git_show_in_new_buf = git_show_in_new_buf
M.in_diff_mode = in_diff_mode

return M
