local util = {}

function util.buf_size(buf)
	return vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
end

return util
