let g:UltiSnipsExpandTrigger="<S-tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"

autocmd filetype c :UltiSnipsAddFiletypes c.c_java
autocmd filetype java :UltiSnipsAddFiletypes java.c_java
autocmd filetype tex :UltiSnipsAddFiletypes tex.md_tex_base.md_tex_math
autocmd filetype markdown :UltiSnipsAddFiletypes markdown.md_tex_base.md_tex_math
autocmd filetype typescript :UltiSnipsAddFiletypes typescript.js_ts
autocmd filetype javascript :UltiSnipsAddFiletypes javascript.js_ts
