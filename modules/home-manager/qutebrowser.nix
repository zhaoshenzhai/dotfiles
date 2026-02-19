{ pkgs, lib, ... }: {
    programs.qutebrowser = {
        enable = true;
        loadAutoconfig = false;

package = pkgs.qutebrowser.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        # Remove the default blue SVG so Qt is forced to use the PNGs
        rm -f qutebrowser/icons/qutebrowser.svg
        
        # Replace the internal PNGs with your custom gray PNG
        # Note: Qt will downscale the 512x512 PNG automatically for smaller sizes
        for size in 16 24 32 48 64 128 256 512; do
          if [ -f "qutebrowser/icons/qutebrowser-$sizex$size.png" ]; then
            cp ${./qutebrowser/qutebrowser.png} "qutebrowser/icons/qutebrowser-$sizex$size.png"
          fi
        done
      '';

      postInstall = (old.postInstall or "") + ''
        # Replace the macOS .app bundle icon
        if [ -d "$out/Applications/qutebrowser.app/Contents/Resources" ]; then
          cp ${./qutebrowser/qutebrowser.icns} "$out/Applications/qutebrowser.app/Contents/Resources/qutebrowser.icns"
        fi
      '';
    });

        searchEngines = {
            DEFAULT = "https://www.google.com/search?q={}";
            yt = "https://www.youtube.com/results?search_query={}";
        };

        settings = {
            url.start_pages = [ "https://google.com" ];
            url.default_page = "https://google.com";
            "auto_save.session" = false;
            "qt.args" = [ 
                "disable-gpu-driver-bug-workarounds"
                "enable-native-gpu-memory-buffers"
                "num-raster-threads=4"
            ];

            statusbar.show = "always";
            tabs.show = "multiple";
            tabs.favicons.scale = 0.9;
            tabs.indicator.width = 0;
            tabs.max_width = 350;
            zoom.default = "100%";
            scrolling.smooth = true;

            fonts = {
                default_family = "Courier Prime";
                default_size = "20pt";
                tabs.selected = "bold default_size default_family";
                tabs.unselected = "bold default_size default_family";
                statusbar = "bold default_size default_family";
            };

            editor.command = [ "alacritty" "-e" "nvim" "{}" ];
            fileselect.handler = "external";

            fileselect.single_file.command = [
                "${pkgs.alacritty}/bin/alacritty"
                "--title" "vifm-float"
                "--option" "window.dimensions={columns=100,lines=35}"
                "--option" "window.position={x=525,y=250}"
                "-e" "${pkgs.vifm}/bin/vifm"
                "-c" ":only"
                "--choose-files" "{}"
            ];
            fileselect.multiple_files.command = [
                "${pkgs.alacritty}/bin/alacritty"
                "--title" "vifm-float"
                "--option" "window.dimensions={columns=100,lines=35}"
                "--option" "window.position={x=525,y=250}"
                "-e" "${pkgs.vifm}/bin/vifm"
                "-c" ":set nodotfiles | filter Applications|Desktop|Documents|Library|Movies|Music|Pictures | :only"
                "--choose-files" "{}"
            ];

            downloads.remove_finished = 1000;
            downloads.location.directory = "~/Downloads";
            downloads.prevent_mixed_content = false;

            content.fullscreen.window = true;
            content.tls.certificate_errors = "block";
            colors.webpage.preferred_color_scheme = "dark";

            colors = {
                messages = {
                    info.bg = "#1e2127";
                    warning.bg = "#1e2127";
                    error.bg = "#1e2127";
                    info.border = "#1e2127";
                    warning.border = "#1e2127";
                    error.border = "#1e2127";
                    warning.fg = "#a8a8aa";
                };
                statusbar = {
                    normal.bg = "#1e2127";
                    normal.fg = "#a8a8aa";
                    insert.bg = "#1e2127";
                    insert.fg = "#a8a8aa";
                    command.bg = "#1e2127";
                    command.fg = "#a8a8aa";
                    url.fg = "#a8a8aa";
                    url.hover.fg = "#f8f8ff";
                    url.success.http.fg = "#a8a8aa";
                    url.success.https.fg = "#a8a8aa";
                };
                tabs = {
                    bar.bg = "#1e2127";
                    even.bg = "#1e2127";
                    odd.bg = "#1e2127";
                    even.fg = "#a8a8a8";
                    odd.fg = "#a8a8a8";
                    selected.even.bg = "#1e2127";
                    selected.odd.bg = "#1e2127";
                    selected.even.fg = "#f8f8ff";
                    selected.odd.fg = "#f8f8ff";
                    pinned = {
                        even.bg = "#1e2127";
                        odd.bg = "#1e2127";
                        even.fg = "#a8a8a8";
                        odd.fg = "#a8a8a8";
                        selected.even.bg = "#1e2127";
                        selected.odd.bg = "#1e2127";
                        selected.even.fg = "#f8f8ff";
                        selected.odd.fg = "#f8f8ff";
                    };
                };
                completion = {
                    fg = "#abb2bf";
                    odd.bg = "#1e2127";
                    even.bg = "#1e2127";
                    match.fg = "#e06c75";

                    category = {
                        fg = "#61afef";
                        bg = "#1e2127";
                        border.top = "#1e2127";
                        border.bottom = "#1e2127";
                    };

                    item.selected = {
                        fg = "#282c34";
                        bg = "#98c379";
                        border.top = "#98c379";
                        border.bottom = "#98c379";
                        match.fg = "#e06c75";
                    };

                    scrollbar = {
                        fg = "#abb2bf";
                        bg = "#1e2127";
                    };
                };
                prompts.bg = "#1e2127";
                downloads.bar.bg = "#1e2127";
            };
        };

        # Key Bindings
        keyBindings = {
            normal = {
                "<Ctrl+Return>" = "cmd-set-text -s :open -t";

                "<Ctrl+=>" = "zoom-in";
                "<Ctrl+->" = "zoom-out";
                "<Ctrl+0>" = "zoom 100";
                
                "<Ctrl+h>" = "back";
                "<Ctrl+l>" = "forward";
                "<Ctrl+j>" = "tab-prev";
                "<Ctrl+k>" = "tab-next";
                "<Ctrl+w>" = "tab-close";
                "<Ctrl+u>" = "cmd-repeat 20 scroll up";
                "<Ctrl+d>" = "cmd-repeat 20 scroll down";
                
                "<Ctrl+Shift+r>" = "restart";
                "<Ctrl+`>" = "config-cycle statusbar.show always never;; config-cycle tabs.show multiple never";

                "<Ctrl+1>" = "tab-select 1";
                "<Ctrl+2>" = "tab-select 2";
                "<Ctrl+3>" = "tab-select 3";
                "<Ctrl+4>" = "tab-select 4";
                "<Ctrl+5>" = "tab-select 5";
                "<Ctrl+6>" = "tab-select 6";
                "<Ctrl+7>" = "tab-select 7";
                "<Ctrl+8>" = "tab-select 8";
                "<Ctrl+9>" = "tab-select 9";

                "<Ctrl+q>" = "nop";
            };
            command = {
                "<Ctrl+j>" = "completion-item-focus next";
                "<Ctrl+k>" = "completion-item-focus prev";
                "<Ctrl+q>" = "mode-enter normal";
            };
        };
    };

    home.file = {
        ".qutebrowser/quickmarks".source = ./qutebrowser/quickmarks;
    };

    home.activation.installQutebrowserBookmarks = lib.hm.dag.entryAfter ["writeBoundary"] ''
        DATA_DIR="$HOME/.qutebrowser/bookmarks"
        mkdir -p "$DATA_DIR"
        cp -f "${./qutebrowser/bookmarks}" "$DATA_DIR/urls"
        chmod u+w "$DATA_DIR/urls"
    '';
}
