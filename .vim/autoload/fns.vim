set scrolloff=999

function fns#ShowDocs()
	if (index(['vim','help'], &filetype) >= 0)
		execute 'h '.expand('<cword>')
	else
		lua vim.lsp.buf.hover()
	endif
endfunction

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

function MyTabLine()
	let s = '' " complete tabline goes here
	" loop through each tab page
	for t in range(tabpagenr('$'))
		" set highlight
		if t + 1 == tabpagenr()
			let s .= '%#TabLineSel#'
		else
			let s .= '%#TabLine#'
		endif
		" set the tab page number (for mouse clicks)
		let s .= '%' . (t + 1) . 'T'
		let s .= ' '
		" set page number string
		let s .= t + 1 . ' '
		" get buffer names and statuses
		let n = ''      "temp string for buffer names while we loop and check buftype
		let m = 0       " &modified counter
		let bc = len(tabpagebuflist(t + 1))     "counter to avoid last ' '
		" loop through each buffer in a tab
		for b in tabpagebuflist(t + 1)
			" buffer types: quickfix gets a [Q], help gets [H]{base fname}
			" others get 1dir/2dir/3dir/fname shortened to 1/2/3/fname
			if getbufvar( b, "&buftype" ) == 'help'
				let n .= '[H]' . fnamemodify( bufname(b), ':t:s/.txt$//' )
			elseif getbufvar( b, "&buftype" ) == 'quickfix'
				let n .= '[Q]'
			else
				let n .= pathshorten(bufname(b))
			endif
			" check and ++ tab's &modified count
			if getbufvar( b, "&modified" )
				let m += 1
			endif
			" no final ' ' added...formatting looks better done later
			if bc > 1
				let n .= ' '
			endif
			let bc -= 1
		endfor
		" add modified label [n+] where n pages in tab are modified
		if m > 0
			let s .= '[' . m . '+]'
		endif
		" select the highlighting for the buffer names
		" my default highlighting only underlines the active tab
		" buffer names.
		if t + 1 == tabpagenr()
			let s .= '%#TabLineSel#'
		else
			let s .= '%#TabLine#'
		endif
		" add buffer names
		if n == ''
			let s.= '[New]'
		else
			let s .= n
		endif
		" switch to no underlining and add final space to buffer list
		let s .= ' '
	endfor
	" after the last tab fill with TabLineFill and reset tab page nr
	let s .= '%#TabLineFill#%T'
	" right-align the label to close the current tab page
	if tabpagenr('$') > 1
		let s .= '%=%#TabLineFill#%999Xclose'
	endif
	return s
endfunction
