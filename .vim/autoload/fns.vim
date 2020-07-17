set scrolloff=999

function! fns#CursorLockToggle()
	if &scrolloff
		setlocal scrolloff=0
	else
		setlocal scrolloff=999
	endif
endfunction

function! fns#FileSize()
	" Blatantly assuming we won't ever edit files larger than 1024GB.
	let units = ['B', 'KB', 'MB', 'GB']
	let size = getfsize(expand('%:p'))
	let i = 0
	while size > 1024
		let size = size / 1024.0
		let i += 1
	endwhile
	let unit = units[i]
	let format = unit == 'B' ? '%.0f%s' : '%.1f%s'
	return printf(format, size, unit)
endfunction

function fns#MoveToPrevTab()
	"there is only one window
	if tabpagenr('$') == 1 && winnr('$') == 1
		return
	endif
	"preparing new window
	let l:tab_nr = tabpagenr('$')
	let l:cur_buf = bufnr('%')
	if tabpagenr() != 1
		close!
		if l:tab_nr == tabpagenr('$')
			tabprev
		endif
		sp
	else
		close!
		exe "0tabnew"
	endif
	"opening current buffer in new window
	exe "b".l:cur_buf
endfunction

function fns#MoveToNextTab()
	"there is only one window
	if tabpagenr('$') == 1 && winnr('$') == 1
		return
	endif
	"preparing new window
	let l:tab_nr = tabpagenr('$')
	let l:cur_buf = bufnr('%')
	if tabpagenr() < tab_nr
		close!
		if l:tab_nr == tabpagenr('$')
			tabnext
		endif
		sp
	else
		close!
		tabnew
	endif
	"opening current buffer in new window
	exe "b".l:cur_buf
endfunction

function! fns#GotoOrOpen(command, ...)
	for file in a:000
		if a:command == 'e'
			exec 'e ' . file
		else
			exec "tab drop " . file
		endif
	endfor
endfunction