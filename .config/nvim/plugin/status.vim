let s:branch = ''

function! Branch()
	return s:branch
endfunction

function! GitBranch()
endfunction

function! UpdateBranch()
	let s:branch = system("git rev-parse --abbrev-ref HEAD 2>/dev/null | tr -d '\n'")
endfunction

" TODO currently using a slow timer instead of autocmd CursorHold
" every time 'system' is called there's a cursor flicker.
call timer_start(10000, { tid -> execute('call UpdateBranch()') }, {'repeat': -1})

function! GitStatus()
	let [a,m,r] = GitGutterGetHunkSummary()
	return printf('+%d ~%d -%d', a, m, r)
endfunction

set statusline=
set statusline+=%#LineNr#
set statusline+=\ %{Branch()}
set statusline+=\ %{GitStatus()}
set statusline+=%#LineNr#
set statusline+=\ %m
set statusline+=\ %f
set statusline+=%=
set statusline+=%#LineNr#
set statusline+=\ %y
set statusline+=\ %{&fileencoding?&fileencoding:&encoding}
set statusline+=\[%{&fileformat}\]
set statusline+=\ %{fns#FileSize()}
set statusline+=\ %p%%
set statusline+=\ %l:%c
set statusline+=\ 
