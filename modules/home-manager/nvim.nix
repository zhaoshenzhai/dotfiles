{ pkgs, lib, ... }:
    let
        myPython = pkgs.python3.withPackages (ps: [ ps.pynvim ]);
        snippetDir = ./nvim/UltiSnips;
            snippetFiles = builtins.filter
                (name: lib.hasSuffix ".snippets" name)
                (builtins.attrNames (builtins.readDir snippetDir));

            snippetExtraFiles = lib.listToAttrs (map (name: {
                name = "/UltiSnips/${name}";
                value = { source = "${snippetDir}/${name}"; };
            }) snippetFiles);
    in {
    programs.nixvim = {
        enable = true;
        defaultEditor = true;
        colorschemes.onedark.enable = true;

        opts = {
            number = true;
            relativenumber = true;
            tabstop = 4;
            softtabstop = 4;
            expandtab = true;
            shiftwidth = 4;

            termguicolors = true;
            title = true;
            incsearch = true;
            wrap = true;
            breakindent = true;
            linebreak = true;

            clipboard = "unnamedplus";
            autoindent = true;
            spell = true;
            spelllang = "en";
            ignorecase = true;
            foldmethod = "manual";
            completeopt = ["menu" "menuone" "noselect"];

            hlsearch = false;
            swapfile = false;
            showmode = false;
            laststatus = 3;

            spellfile = "/Users/zhao/iCloud/Dotfiles/modules/home-manager/nvim/spell/en.utf-8.add";
        };

        plugins = {
            vimtex = {
                enable = true;
                settings = {
                    view_method = "skim";
                    view_general_options = "--synctex-forward @line:@col:@tex @pdf";
                    view_forward_search_on_start = true;
                    mappings_enabled = false;
                    quickfix_ignore_filters = [
                        "Underfull \\\\hbox (badness [0-9]*) in paragraph at lines"
                        "Overfull \\\\hbox ([0-9]*.[0-9]*pt too wide) in paragraph at lines"
                        "Underfull \\\\hbox (badness [0-9]*) in "
                        "Underfull \\\\vbox (badness [0-9]*) detected at line "
                        "Overfull \\\\hbox ([0-9]*.[0-9]*pt too wide) in "
                        "Package hyperref Warning: Token not allowed in a PDF string"
                        "Package typearea Warning: Bad type area settings!"
                        "LaTeX Warning: Label(s) may have changed. Rerun to get cross-references right."
                        "Dimension too large."
                        "I found no \\\\bibdata command"
                        "LaTeX Warning: Marginpar on page * moved."
                        "LaTeX Warning: There were undefined references."
                        "Package biblatex Warning: Please rerun LaTeX."
                    ];
                };
            };

            cmp = {
                enable = true;
                autoEnableSources = true;

                settings = {
                    mapping = {
                        "<C-j>" = "cmp.mapping.select_next_item()";
                        "<C-k>" = "cmp.mapping.select_prev_item()";
                        "<C-l>" = "cmp.mapping.confirm({ select = true })";
                        "<C-Space>" = "cmp.mapping.complete()";
                    };

                    sources = [
                        { name = "ultisnips"; }
                        { name = "omni"; }
                        { name = "buffer"; }
                        { name = "path"; }
                    ];
                };
            };

            lualine = {
                enable = true;
                settings = {
                    options = {
                        theme = "onedark";
                        icons_enabled = true;
                        component_separators = "";
                        section_separators = "";
                    };
                    
                    sections = {
                        lualine_a = [ "mode" ];
                        lualine_b = [
                            {
                                __unkeyed-1 = "filename";
                                path = 3;
                            }
                        ];
                        lualine_c = { __raw = "{}"; };
                        
                        lualine_x = { __raw = "{}"; };
                        lualine_y = [ "location" ];
                        lualine_z = [ "progress" ];
                    };
                };
            };
        };

        extraPlugins = with pkgs.vimPlugins; [ ultisnips ];

        globals = {
            UltiSnipsExpandTrigger = "<S-tab>";
            UltiSnipsJumpForwardTrigger = "<tab>";
            UltiSnipsSnippetDirectories = [ "UltiSnips" ];
            vimtex_compiler_latexmk = {
                executable = "${pkgs.texlive.combined.scheme-full}/bin/latexmk";
                options = [
                    "-synctex=1"
                    "-interaction=nonstopmode"
                ];
            };
        };

        extraFiles = {
            "ftplugin/tex.vim".text = ''
                nnoremap <buffer> <C-1> :w <CR>:VimtexCompile<CR>
                nnoremap <buffer> <C-2> :w <CR>:VimtexView<CR>

                nnoremap <buffer> <C-3> :w <CR>:!rm -f *.aux(N) *.bbl(N) *.bcf(N) *bcf-SAVE-ERROR(N) *.blg(N) *.fdb_latexmk(N) *.fls(N) *.log(N) *.run.xml(N) *.synctex.gz(N) *.synctex\(busy\)(N)<CR><CR>

                nnoremap <buffer> <C-4> :w <CR>:lua local f=vim.fn.expand('%:p:r')..'_Student.pdf'; if vim.fn.filereadable(f)==1 then vim.fn.jobstart({'zathura', f}, {detach=true}) end<CR><CR>
            '';
        } // snippetExtraFiles;

        extraConfigLua = ''
            vim.opt.shortmess:append("c")
        '';

        extraConfigVim = ''
            function! ScreenMovement(movement)
                if &wrap
                    return "g" . a:movement
                else
                    return a:movement
                endif
            endfunction
        '';

        keymaps = [
            {
                mode = "n";
                key = "<C-f>";
                action = ":%s//gc<Left><Left><Left>";
            }
            {
                mode = "v";
                key = "<C-f>";
                action = ":s//gc<Left><Left><Left>";
            }
            {
                mode = "n";
                key = "<C-s>";
                action = ":set spell!<CR>";
                options = { silent = true; };
            }
            {
                mode = "i";
                key = "<C-c>";
                action = "<c-g>u<Esc>[s1z=`]a<c-g>u";
                options = { silent = true; };
            }
            {
                mode = "n";
                key = "<C-c>";
                action = "mz[s1z=`z";
                options = { silent = true; };
            }
            {
                mode = "x";
                key = "im";
                action = "T$ot$";
                options = { silent = true; };
            }
            {
                mode = "o";
                key = "im";
                action = ":normal vim<CR>";
                options = { silent = true; };
            }

            {
                mode = "x";
                key = "am";
                action = "F$of$";
                options = { silent = true; };
            }
            {
                mode = "o";
                key = "am";
                action = ":normal vam<CR>";
                options = { silent = true; };
            }
            {
                mode = ["n" "o"];
                key = "j";
                action = "ScreenMovement('j')";
                options = { expr = true; silent = true; };
            }
            {
                mode = ["n" "o"];
                key = "k";
                action = "ScreenMovement('k')";
                options = { expr = true; silent = true; };
            }
            {
                mode = ["n" "o"];
                key = "0";
                action = "ScreenMovement('0')";
                options = { expr = true; silent = true; };
            }
            {
                mode = ["n" "o"];
                key = "^";
                action = "ScreenMovement('^')";
                options = { expr = true; silent = true; };
            }
            {
                mode = ["n" "o"];
                key = "$";
                action = "ScreenMovement('$')";
                options = { expr = true; silent = true; };
            }
        ];

        highlight = {
            Normal = { ctermbg = "none"; bg = "none"; };
            NonText = { ctermbg = "none"; bg = "none"; };
            LineNr = { ctermbg = "none"; bg = "none"; };
            SignColumn = { ctermbg = "none"; bg = "none"; };
            EndOfBuffer = { ctermbg = "none"; bg = "none"; };
            Folded = { ctermbg = "none"; bg = "none"; fg = "#abb2bf"; };
        };

        autoGroups = {
            remember_folds = {
                clear = true;
            };
        };

        autoCmd = [
            {
                event = [ "BufWinLeave" ];
                pattern = [ "*" ];
                command = "if expand('%') != '' && &buftype == '' | mkview | endif";
                group = "remember_folds";
            }
            {
                event = [ "BufWinEnter" ];
                pattern = [ "*" ];
                command = "if expand('%') != '' && &buftype == '' | silent! loadview | endif";
                group = "remember_folds";
            }
        ];

        withPython3 = true;
        extraPython3Packages = ps: [ ps.pynvim ];
        globals.python3_host_prog = "${myPython}/bin/python3";
    };
}
