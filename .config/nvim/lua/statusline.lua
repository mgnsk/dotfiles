function _G.file_size()
    local file = vim.fn.expand("%:p")
    if string.len(file) == 0 then
        return ""
    end

    local size = vim.fn.getfsize(file)
    if size <= 0 then
        return ""
    end

    local units = { "B", "KB", "MB", "GB" }

    local i = 1
    while size > 1024 do
        size = size / 1024
        i = i + 1
    end

    local unit = units[i]
    local format = unit == "B" and "%.0f%s" or "%.1f%s"
    return string.format(format, size, unit)
end

function _G.git_status_line()
    local success, head = pcall(vim.fn["FugitiveHead"])
    if not success or not head or head == "" then
        return ""
    end

    local success, g = pcall(vim.fn["GitGutterGetHunkSummary"])
    if not success or not g then
        return ""
    end

    local s = { head }

    for i, symbol in ipairs({ "+", "~", "-" }) do
        if g[i] > 0 then
            table.insert(s, string.format("%s%d", symbol, g[i]))
        end
    end

    return table.concat(s, " ")
end

vim.opt.statusline = table.concat({
    "%#LineNr#",
    "%{v:lua.git_status_line()}",
    "%#LineNr#",
    " %m",
    " %f",
    "%=",
    "%#LineNr#",
    " %y",
    " %{&fileencoding?&fileencoding:&encoding}",
    "[%{&fileformat}]",
    " %{v:lua.file_size()}",
    " %p%%",
    " %l:%c",
})
