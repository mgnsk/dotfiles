" Modified version of https://github.com/athom/more-colorful.vim/blob/master/after/syntax/go.vim

syn match goMethod 	 /\(.\)\@<=\w\+\((\)\@=/
hi def link     goMethod         Function
