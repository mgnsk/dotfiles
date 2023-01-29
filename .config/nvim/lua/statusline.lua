local function status_line()
    return table.concat({
        "%#LineNr#",
        "%{FugitiveStatusline()}",
        " %{get(b:,'gitsigns_status','')}",
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
end

vim.opt.statusline = status_line()
