let g:UltiSnipsExpandTrigger="<S-tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"

autocmd filetype tex :UltiSnipsAddFiletypes tex.md_tex
autocmd filetype markdown :UltiSnipsAddFiletypes markdown.md_tex
autocmd filetype typescript :UltiSnipsAddFiletypes typescript.js_ts
autocmd filetype javascript :UltiSnipsAddFiletypes javascript.js_ts
