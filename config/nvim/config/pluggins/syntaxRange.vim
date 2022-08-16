autocmd filetype markdown :call SyntaxRange#Include('\$', '\$', 'tex', 'tex', '@spell')
autocmd filetype markdown :call SyntaxRange#Include('\$\$', '\$\$', 'tex', 'tex', '@spell')
autocmd filetype markdown :call SyntaxRange#Include('``` ad-', '```', 'markdown', 'markdown', '@spell')
