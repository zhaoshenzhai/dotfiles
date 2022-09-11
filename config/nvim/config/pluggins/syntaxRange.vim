autocmd filetype markdown :call SyntaxRange#Include('---', '---', 'tex', 'tex')
autocmd filetype markdown :call SyntaxRange#Include('``` ad-', '```', 'markdown', 'markdown', '@spell')
