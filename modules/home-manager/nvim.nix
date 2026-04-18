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
        globals.python3_host_prog = "${myPython}/bin/python3";

        plugins = {
            treesitter = {
                enable = true;
                settings = {
                    highlight = {
                        enable = true;
                        additional_vim_regex_highlighting = false;
                    };
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
                        { name = "tex"; }
                        { name = "attic"; }
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
            "lua/c.lua".source         = ./nvim/c.lua;
            "lua/ui.lua".source        = ./nvim/ui.lua;
            "lua/tex.lua".source       = ./nvim/tex.lua;
            "lua/tabs.lua".source      = ./nvim/tabs.lua;
            "lua/attic.lua".source     = ./nvim/attic.lua;
            "lua/options.lua".source   = ./nvim/options.lua;
            "lua/keymaps.lua".source   = ./nvim/keymaps.lua;
            "lua/autocmds.lua".source  = ./nvim/autocmds.lua;
            "lua/aerospace.lua".source = ./nvim/aerospace.lua;
        } // snippetExtraFiles;

        extraConfigLua = ''
            require('c')
            require('ui')
            require('tex')
            require('tabs')
            require('attic')
            require('options')
            require('keymaps')
            require('autocmds')
            require('aerospace')
        '';
    };
}
