local M = {}

---@return {start_line: number, end_line: number}
function M.selection()
	local cursor_line = vim.fn.line(".")
	local end_line = vim.fn.line("v")

	if cursor_line < end_line then
		return { cursor_line, end_line }
	else
		return { end_line, cursor_line }
	end
end

return M
