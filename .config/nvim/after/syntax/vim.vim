" Based on the excellent answer at: https://vi.stackexchange.com/questions/19088/highlighting-another-syntax-in-a-shell-heredoc/19411#19411
" safe b:current_syntax to restore it afterwards
" Value could be 'sh', 'posix', 'ksh' or 'bash'
let s:cs_safe = b:current_syntax

" unlet b:current_syntax, so sql.vim will load
unlet b:current_syntax
syntax include @LUA syntax/lua.vim

" restore saved syntax
let b:current_syntax = s:cs_safe

syn region vimHereDoc matchgroup=vimHereDocLua start=".*<<\s*\\\=\z(LUA\)" matchgroup=vimHereDocLua end="^\z1\s*$"   contains=@LUA
hi def link vimHereDocSql        vimRedir
