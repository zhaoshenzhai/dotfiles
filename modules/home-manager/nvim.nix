{ pkgs, lib, ... }: let
    myPython = pkgs.python3.withPackages (ps: [ ps.pynvim ]);
    snippetDir = ./nvim/UltiSnips;
    snippetFiles = builtins.filter (name: lib.hasSuffix ".snippets" name) (builtins.attrNames (builtins.readDir snippetDir));

    snippetExtraFiles = lib.listToAttrs (map (name: {
        name = "/UltiSnips/${name}";
        value = { source = "${snippetDir}/${name}"; };
    }) snippetFiles);
in {
    home.packages = [ pkgs.neovim-remote ];
    programs.nixvim = {
        enable = true;
        defaultEditor = true;
        colorschemes.onedark.enable = true;

        withPython3 = true;
        extraPython3Packages = ps: [ ps.pynvim ];

        globals = {
            vimtex_compiler_latexmk = {
                executable = "${pkgs.texlive.combined.scheme-full}/bin/latexmk";
                options = [ "-synctex=1" "-interaction=nonstopmode" ];
            };
            python3_host_prog = "${myPython}/bin/python3";
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
                        "<C-j>" = "cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert })";
                        "<C-k>" = "cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert })";
                        "<C-l>" = "cmp.mapping.confirm({ select = true })";
                        "<C-Space>" = "cmp.mapping.complete()";
                    };
                    sources = [
                        { name = "ultisnips"; }
                        { name = "attic"; }
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
                        theme = {
                            __raw = ''
                                (function()
                                    local theme = require('lualine.themes.onedark')
                                    for _, mode in pairs(theme) do
                                        if type(mode) == 'table' then
                                            mode.b = mode.b or {}
                                            mode.b.bg = 'NONE'
                                            mode.c = mode.c or {}
                                            mode.c.bg = 'NONE'
                                            mode.y = mode.y or {}
                                            mode.y.bg = 'NONE'
                                        end
                                    end
                                    return theme
                                end)()
                            '';
                        };
                        icons_enabled = true;
                        component_separators = "";
                        section_separators = "";
                    };
                    sections = {
                        lualine_a = [ "mode" ];
                        lualine_b = [ { __unkeyed-1 = "filename"; path = 3; } ];
                        lualine_c = { __raw = "{}"; };
                        lualine_x = { __raw = "{}"; };
                        lualine_y = [ "location" ];
                        lualine_z = [ "progress" ];
                    };
                };
            };
        };

        extraPlugins = with pkgs.vimPlugins; [ ultisnips ];
        extraFiles = {
            "lua/options.lua".source   = ./nvim/options.lua;
            "lua/ui.lua".source        = ./nvim/ui.lua;
            "lua/keymaps.lua".source   = ./nvim/keymaps.lua;
            "lua/autocmds.lua".source  = ./nvim/autocmds.lua;
            "lua/tabs.lua".source      = ./nvim/tabs.lua;
            "lua/aerospace.lua".source = ./nvim/aerospace.lua;
            "lua/attic.lua".source     = ./nvim/attic.lua;
            "ftplugin/tex.lua".source  = ./nvim/tex.lua;
        } // snippetExtraFiles;
        extraConfigLua = ''
            require('options')
            require('ui')
            require('keymaps')
            require('autocmds')
            require('tabs')
            require('aerospace')
            require('attic')
        '';
    };
}
