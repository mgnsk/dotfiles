autocmd BufWritePre *.vert,*.tesc,*.tese,*.geom,*.frag,*.comp,*.glsl silent call fns#Format()
