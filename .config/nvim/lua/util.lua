local M = {}

local function git_show_in_new_buf(commit)
	local output = vim.fn.systemlist("git show " .. commit)
	vim.cmd("tabnew")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
	vim.bo.buftype = "nofile"
	vim.bo.bufhidden = "wipe"
	vim.bo.modifiable = false
	vim.bo.filetype = "git"
end

M.treesitter_max_filesize = 256 * 1024
M.git_show_in_new_buf = git_show_in_new_buf

return M
