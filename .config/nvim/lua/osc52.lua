function _G.osc52(content)
    local w = assert(io.open("/dev/tty", "w"))
    assert(w:write(string.format("\x1b]52;c;%s\x1b", require("base64").encode(content))))
    assert(w:close())
end

-- https://github.com/neovim/neovim/issues/13436
local clipboard = [[
let g:clipboard = {
    'name': 'myClipboard',
    'copy': {
        '+': {lines, regtype -> v:lua.osc52(join(lines, "\n"))}
    },
    'paste': {
        '+': ''
    }
}
]]

vim.api.nvim_exec(string.gsub(clipboard, "[\r\n]", ""), false)
