syn match goMethod 	 /\(.\)\@<=\w\+\((\)\@=/
hi def link     goMethod         Function

syn match goTypeConstructor      /\<\w\+{\@=/
hi def link     goTypeConstructor   Type
