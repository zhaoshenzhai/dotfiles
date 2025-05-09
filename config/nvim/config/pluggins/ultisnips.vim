let g:UltiSnipsExpandTrigger="<S-tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"

autocmd filetype c :UltiSnipsAddFiletypes c_java
autocmd filetype md :UltiSnipsAddFiletypes tex_md
"autocmd filetype tex :UltiSnipsAddFiletypes tex_md
autocmd filetype java :UltiSnipsAddFiletypes c_java
autocmd filetype typescript :UltiSnipsAddFiletypes js_ts
autocmd filetype javascript :UltiSnipsAddFiletypes js_ts
