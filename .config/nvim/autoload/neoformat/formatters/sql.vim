function! neoformat#formatters#sql#enabled() abort
    return ['sqlformatter']
endfunction

function! neoformat#formatters#sql#sqlformatter() abort
    return {
        \ 'exe': 'sql-formatter-cli',
        \ 'stdin': 1
        \ }
endfunction
