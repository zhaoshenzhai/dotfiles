let g:UltiSnipsExpandTrigger="<S-tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"

autocmd filetype c :UltiSnipsAddFiletypes c.c_java
autocmd filetype java :UltiSnipsAddFiletypes java.c_java
autocmd filetype tex :UltiSnipsAddFiletypes md_tex_base.md_tex_math.tex
autocmd filetype markdown :UltiSnipsAddFiletypes md_tex_base.md_tex_math.markdown
autocmd filetype typescript :UltiSnipsAddFiletypes typescript.js_ts
autocmd filetype javascript :UltiSnipsAddFiletypes javascript.js_ts
